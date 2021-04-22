This repository proposes an app architecture for medium-sized iOS apps based on latest trends as of 2021. It features:

# SwiftUI + MVVM + Redux + Clean Architecture + Combine

This sample app is not meant to be super finished and code is not super clean. It just serves as a way to explore concepts of the architecture.

**Feedback of any type is very welcome!**

## What this code does

It is a little unfinished app which is using YouTube Data API to search for YouTube videos, shows detail of video and allows to favorite it (save to local DB).

To be able to load the API requests successfully, you’ll have to register your YouTube Data API account and provide the correct API key.
I didnt care about UI that much, since its not important for us here. It is unfinished and often uses dummy data.

## High level architecture overview

### Presentation Layer

UI layer consists of SwiftUI views which are using ViewModels and observe their `@Published` properties.

ViewModels internally operate on a `State`. The `State` however contains business logic models (Entities) that are not suitable to hand over directly to Views. Instead, ViewModels should format `State` data in a way their View exactly needs it (and transform it into `@Published` vars)

### Domain Layer

Main logic inside ViewModels is driven using Redux-style state machine. Big thanks for this belongs to guys from [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) from which I took implementation of `Store`, `Reducer`, `Feedback` (and did some minor changes).

ViewModels are initialized by providing `Store` which drives app logic for a particular ViewModels' State and Actions. 

The `Store` is given some dependencies represented by `Environment` struct. These dependencies try to follow [Clean Architecture principles](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3), so they should consist of `UseCases` which operate on business logic `Entities` and have injected dependencies for `Repositories`.

### Data layer

Data layer contains most low level code (Repositories) which are responsible for running API requests, communicating to local DB etc. I paid only minor attention to this layer because my aim was not to focus much on details of where data are stored or taken from. It’s there just to explore how it works in terms of dependency injection and testability.


## Dive into the code
Let's briefly check how this all works together.

### Views are using ViewModels exclusively

And ViewModels are (currently) responsible for creating child ViewModels. Since they have to give them their `store` which I try to keep as private as possible.

```swift
struct VideosListView: View {
    @ObservedObject var viewModel: VideosListViewModel

    var body: some View {
        NavigationView {
            ...
            List(viewModel.videos) { item in
                NavigationLink(
                    destination: VideoDetailView(
                        viewModel: viewModel.viewModel(forDetailOf: item)
                    ),
                    label: {
                        VideoInfoView(video: .init(video: item), isLiked: item.isLiked)
                            .padding(5)
                    }
                )
            }
            ...
        }
    }
}
```

### ViewModels internaly operate on Redux state machine
They define their own `State`, `Actions`, `Environment`, `Reducer`, `Effect`.

```swift
extension VideoDetailViewModel {
    typealias StoreType = Store<State, Action>

    enum Error: Swift.Error, Equatable {
        case couldNotLikeVideo
        case couldNotDislikeVideo
    }

    struct State {
        let video: Video
        var isLiked: Bool
        var likeVideoError: Error?

        init(video: Video, isLiked: Bool, likeVideoError: Error? = nil) {
            self.video = video
            self.isLiked = isLiked
            self.likeVideoError = likeVideoError
        }
    }

    enum Action {
        case likeVideo
        case videoLiked
        case dislikeVideo
        case videoDisliked
        case onLikeVideoError(Error)
    }

    struct Environment {
        var likeVideo: LikeVideoUseCase
    }
}

extension VideoDetailViewModel {
    typealias ReducerType = Reducer<State, Action, Environment>

    static var reducer: ReducerType = {
        .init { state, action, environment in
            switch action {
            case .likeVideo:
                return Effects.like(video: state.video, using: environment.likeVideo)

            case .dislikeVideo:
                return Effects.dislike(video: state.video, using: environment.likeVideo)

            case .onLikeVideoError(_):
                return .none

            case .videoLiked:
                state.isLiked = true
                return .none

            case .videoDisliked:
                state.isLiked = false
                return .none
            }
        }
    }()
}

extension VideoDetailViewModel {
    struct Effects {
        static func like(video: Video, using useCase: LikeVideoUseCase) -> Effect<Action, Never> {
            ...
        }

        static func dislike(video: Video, using useCase: LikeVideoUseCase) -> Effect<Action, Never> {
            ...
        }
    }
}
```

### ViewModels don't expose their `State` to public
Instead they fromat into a form their view exactly needs and provide it using `@Published` properties.

```swift
final class VideosListViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var isLoading: Bool = false

    ...

    init(store: StoreType) {
        self.store = store

        store.publisher.videos
            .map {
                $0.map { [unowned self] video in
                    .init(video: video, isLiked: self.store.state.isLiked(videoId: video.id))
                }
            }
            .assign(to: &self.$videos)

        store.publisher.loading
            .map {
                switch $0 {
                case .idle, .loaded, .error(_):
                    return false
                case .loading(_):
                    return true
                }
            }
            .assign(to: &self.$isLoading)

        ...
    }
    ...
}
```

They as well wrap `store.send(...)` into appropriate public methods.
```swfit
func searchVideos(for searchText: String) {
    store.send(.onSearch(searchText))
}
```

### `Environment` provides dependencies for ViewModels
`Effect`s of view models should use `UseCase`s provided by `Environment`. This is basically a way of dependency injection.
The `Environment` is available inside `Reducer` so we can pass `UseCase` to `Effect` as a method argument.

```swift
extension VideosListViewModel {
    struct Environment {
        var searchVideos: SearchVideosUseCase
    }

    static var reducer: ReducerType = {
        .init { (state, action, environment) -> Effect<Action, Never> in
            switch action {
            case .onSearch(let searchString):
                state.loading = .loading(searchString)
                return Effects.searchStringPublisher(searchText: searchString, using: environment.searchVideos)

            case .onLoadVideos(let videos):
                ...
            case .onAppear:
                ...
            case .onLoadVideosError(let error):
                ...
            }
        }
    }()
}

extension VideosListViewModel {
    struct Effects {
        static func searchStringPublisher(searchText: String, using useCase: SearchVideosUseCase) -> Effect<Action, Never> {
            useCase.videosMatching(searchText)
                .map(Action.onLoadVideos)
                .replaceError(with: .onLoadVideosError(.unknown))
                .eraseToAnyPublisher()
                .eraseToEffect()
        }
    }
}
```

### `UseCase` should interact with `Repository` providing it access to data it needs
```swift
struct LikeVideoUseCase {
    var like: (Video) -> AnyPublisher<Bool, Error>
    var dislike: (Video) -> AnyPublisher<Bool, Error>
}

struct LikeVideoRepository {
    var like: (Video) -> AnyPublisher<Bool, Error>
    var dislike: (Video) -> AnyPublisher<Bool, Error>
}

extension LikeVideoUseCase {
    static func live(repository: LikeVideoRepository) -> Self {
        .init(like: repository.like, dislike: repository.dislike)
    }
}
```
It's intended to allow `Repository` implementation to be replacable for decoupling and testability (this is also called (I think) [Dependency Inversion](https://en.wikipedia.org/wiki/Dependency_inversion_principle)).

### We define concrete repository implementation by using static func receiving concrete implementation as its param
```swift
extension LikeVideoRepository {
    static func coreData(repository: CoreDataVideoPersistenceRepository) -> Self {
        .init(
            like: { video in
                Deferred {
                    Future { promise in
                        do {
                            try repository.saveVideo(video)
                            promise(.success(true))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
                .eraseToAnyPublisher()
            },
            dislike: { video in
                Deferred {
                    Future { promise in
                        do {
                            try repository.deleteVideo(video)
                            promise(.success(true))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
        )
    }
}

extension CoreDataVideoPersistenceRepository {
    static func live(managedObjectContext: NSManagedObjectContext) -> Self {
        .init(
            saveVideo: { video in
                let savedVideo = CDVideo(context: managedObjectContext)
                savedVideo.id = video.id
                savedVideo.title = video.title
                savedVideo.thumbnailUrl = video.imageThumbnailUrl?.absoluteString
                savedVideo.dateSaved = .init()

                try managedObjectContext.save()
            },
            deleteVideo: { video in
                let fetchRequest: NSFetchRequest<CDVideo> = CDVideo.fetchRequest()
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "id", ascending: true)
                ]
                fetchRequest.predicate = .init(format: "id == \(video.id)")

                let videos = try managedObjectContext.fetch(fetchRequest)
                videos.forEach {
                    managedObjectContext.delete($0)
                }

                try managedObjectContext.save()
            },
            savedVideos: {
                let fetchRequest: NSFetchRequest<CDVideo> = CDVideo.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSaved", ascending: true)]
                
                let videos = try managedObjectContext.fetch(fetchRequest)

                return videos.compactMap {
                    guard let id = $0.id, let title = $0.title else {
                        return nil
                    }

                    return .init(
                        id: id,
                        title: title,
                        imageThumbnailUrl: $0.thumbnailUrl.map { URL(string: $0) } ?? nil
                    )
                }
            }
        )
    }
}
```

Repositories themself can also have dependencies.
We can make this layer as deep as we need. Depending on what suits to complexity of our app and how we want the code be testable.

### In ViewModels we test only public interfaces, dont touch `State`, `Reducer` etc. directly
```swift
VideosListViewModelTests:

func testSearchVideosShouldPassSearchedStringToSearchVideosUseCase() {
    var actualSearchString = ""
    let environment = VideosListViewModel.Environment(searchVideos: SearchVideosUseCase(videosMatching: {
        actualSearchString = $0
        return .just([])
    }))

    let viewModel = VideosListViewModel(environment: environment)
    let expectedSearchString = "search"

    viewModel.searchVideos(for: expectedSearchString)

    XCTAssertEqual(actualSearchString, expectedSearchString)
}
```

### By passing mock dependencies we can nicely test Repositories as well
```swift
LikeVideoUseCase+CoreDataTests:

func testLikeShouldCallSaveMethod() throws {
    let exp = expectation(description: "Save method called")
    let repository = CoreDataVideoPersistenceRepository(
        saveVideo: { video in
            exp.fulfill()
        },
        deleteVideo: {_ in
            XCTFail("Should not call delete video")
        }, savedVideos: { [] }
    )

    let likeRepository = LikeVideoRepository.coreData(repository: repository)

    let recorder = likeRepository.like(.mock())
        .record()
        .next()

    _ = try wait(for: recorder, timeout: 0.1)
    waitForExpectations(timeout: 0.15)
}
```
BTW: you are able to come up with these dependencies easily if you do TDD. It by nature forces you to create code which can be easily tested = is well decoupled.

## Concepts

Various concepts that might be interesting to think about:

### Creating child stores/states/reducers

For Redux-style state machine I’ve basically copy-pasted `Store`, `Reducer`, `Feedback`  classes from Composable Architecture and did minor adjustments, mostly commented out unneeded code.

But one notable change I made was that I created new `Store.scope` method:

```swift
public func scope<LocalState, LocalAction, LocalEnvironment>(
    toLocalState: @escaping (State) -> (LocalState),
    updateGlobalState: @escaping (inout State, LocalState) -> Void,
    environment: @autoclosure @escaping () -> LocalEnvironment,
    using reducer: Reducer<LocalState, LocalAction, LocalEnvironment>
) -> Store<LocalState, LocalAction> {
    let localStore = Store<LocalState, LocalAction>(
        initialState: toLocalState(self.state),
        reducer: {
            let effect = reducer.run(&$0, $1, environment())
            updateGlobalState(&self.state, $0)
            return effect
        }
    )
    localStore.parentCancellable = self.$state
        .sink { [weak localStore] newValue in
            localStore?.state = toLocalState(newValue)
        }

    return localStore
}
```

This method keeps the parent and child state in sync by using two transformations:
 1) `toLocalState` - derives child (local) state from parent (global) state
 2) `updateGlobalState` - updates parent (global) state in place based on changes inside child (local) state

When creating store scope like this, it allows me to:
- not being forced to decompose child stores based on KeyPath of parent stores (this seems to be a design under which Composable Architecture builds up)
- I can create and execute child state machine (reducer) on-demand, only when it’s actually needed. As opposed to Composable Architecture which is suggesting to `pullback` + `combine` many of small reducers into one huge reducer

I’m wondering why this kind of `scope` method is not part of Composable Architecture initially. But maybe I’m just missing some key concepts of Redux architectures? I had no prior knowledge of it before writing this code.

### Dependencies using Struct instead of Protocols

One of the interesting and (for me) controversial concepts I wanted to try out was to model dependencies using Structs not Protocols. I got motivated for this by talk [by Stephen Celis](https://www.pointfree.co/blog/posts/21-how-to-control-the-world) and Composable Architecture uses it too under name `Environment`. So I tried to follow same principles I’ve seen inside [isowords app](https://github.com/pointfreeco/isowords).

I had mixed feelings about it so [I created a PR](https://github.com/ibru/my-tube/pull/1) to compare struct-based and protocol-based approaches. It helped me to clear out some points about it but I still have mixed feelings. Take a look at the PR and make your own opinion. 
But I guess I'll give it a try on some production app.

### Testability

We all do like to write unit tests, right?
One of the key factors for me is the ease of testability. Which usually tells how well are the code layers separated. So far it seems good to me.
I didn’t aim for a huge amount of test coverage. I just wanted to know how the tests can be written when dependencies are modeled as structs.

In ViewModels tests I try to not rely test behavior on the fact that they use `Store`, `Reducers` etc. internally because it’s an implementation detail. I want my tests to be still saving my ass in case I would decide to switch from Redux to something else. The only elements which should play the role for ViewModels tests are the `@Published` properties, methods and `Environment` providing mock dependencies.

## Reference Materials

- [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)

- [Clean Architecture](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3)

- [How to Control the World](https://www.pointfree.co/blog/posts/21-how-to-control-the-world)

- [Modern MVVM iOS App Architecture with Combine and SwiftUI](https://www.vadimbulavin.com/modern-mvvm-ios-app-architecture-with-combine-and-swiftui/)

- [isowords iOS app](https://github.com/pointfreeco/isowords)

- [Composable Reducers & Effects Systems](https://www.youtube.com/watch?v=QOIigosUNGU)

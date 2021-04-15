//
//  VideosListViewModel.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/26/21.
//

import Foundation
import Combine

struct VideosListEnvironment {
    var searchVideos: SearchVideosClient
}

extension VideosListEnvironment {
    static var live: Self {
        .init(
            searchVideos: .live
        )
    }
}

struct SearchVideosClient {
    var videosMatching: (String) -> AnyPublisher<[VideosListViewModel.VideoItem], Error>
}

extension SearchVideosClient {
    static var live: Self {
        .init(
            videosMatching: {
                YoutubeVideosRepository().videos(for: $0)
                    .map {
                        $0.map {
                            VideosListViewModel.VideoItem(id: $0.id, title: $0.title, imageThumbnailUrl: $0.imageThumbnailUrl)
                        }
                    }
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
        )
    }
}

final class VideosListViewModel: ObservableObject {
    @Published var state: State

    private var bag = Set<AnyCancellable>()

    private let input = PassthroughSubject<Event, Never>()


    init(initialState: State = .init(), environment: VideosListEnvironment = .live) {
        state = initialState

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.searchString(using: environment.searchVideos),
                //Self.debug(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }

    deinit {
        bag.removeAll()
    }

    func send(event: Event) {
        input.send(event)
    }
}

extension VideosListViewModel {
    enum Error: Swift.Error, Equatable {
        case unknown
    }
    struct State: Equatable {
        enum LoadingState: Equatable {
            case idle
            case loading(String)
            case loaded
            case error(Error)
        }

        let loading: LoadingState
        let videos: [VideoItem]

        init(loading: LoadingState = .idle, videos: [VideoItem] = []) {
            self.loading = loading
            self.videos = videos
        }
    }

    enum Event {
        case onAppear
        case onSearch(String)
        case onLoadVideos([VideoItem])
        case onLoadVideosError(Error)
    }
}

extension VideosListViewModel {
    struct VideoItem: Equatable, Identifiable {
        let id: String
        let title: String
        let imageThumbnailUrl: URL?
    }
}


extension VideosListViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case .onSearch(let searchString):
            return .init(loading: .loading(searchString), videos: state.videos)

        case .onLoadVideos(let videos):
            return .init(loading: .loaded, videos: videos)

        default:
            return state
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }

    static func debug() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            print("State changed: \(state)")
            return Empty().eraseToAnyPublisher()
        }
    }

    static func searchString(using searchVideos: SearchVideosClient) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading(let searchText) = state.loading else { return Empty().eraseToAnyPublisher() }

            return searchVideos.videosMatching(searchText)
                .map(Event.onLoadVideos)
                .replaceError(with: .onLoadVideosError(.unknown))
                .eraseToAnyPublisher()
        }
    }
}

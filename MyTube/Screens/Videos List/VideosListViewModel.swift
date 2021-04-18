//
//  VideosListViewModel.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/26/21.
//

import Foundation
import Combine

final class VideosListViewModel: ObservableObject {
    @Published var state: State // TODO: State should belong to Entities layer, not UI layer.

    private var store: Store<State, Action>!

    private var bag = Set<AnyCancellable>()

    convenience init(
        initialState: State = .init(),
        reducer: ReducerType = VideosListViewModel.reducer,
        environment: Environment = .live
    ) {
        self.init(store: .init(initialState: initialState, reducer: reducer, environment: environment))
    }

    init(store: StoreType) {
        self.store = store
        self.state = store.state

        store.$state.assign(to: &self.$state)
    }

    deinit {
        bag.removeAll()
    }

    func send(event: Action) {
        store.send(event)
    }
}

extension VideosListViewModel {
    typealias StoreType = Store<State, Action>
    
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

        var loading: LoadingState
        var videos: [VideoItem]
        
        var likedVideoIDs: Set<String>

        init(loading: LoadingState = .idle, videos: [VideoItem] = [], likedVideoIDs: Set<String> = []) {
            self.loading = loading
            self.videos = videos
            self.likedVideoIDs = likedVideoIDs
        }

        func isLiked(videoId: String) -> Bool {
            likedVideoIDs.contains(videoId)
        }
    }

    enum Action {
        case onAppear
        case onSearch(String)
        case onLoadVideos([VideoItem])
        case onLoadVideosError(Error)
    }

    struct Environment {
        var searchVideos: SearchVideosClient
    }
}

extension VideosListViewModel.Environment {
    static var live: Self {
        .init(
            searchVideos: .live
        )
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
    typealias ReducerType = Reducer<State, Action, Environment>

    static var reducer: ReducerType = {
        .init { (state, action, environment) -> Effect<Action, Never> in
            switch action {
            case .onSearch(let searchString):
                state.loading = .loading(searchString)
                return Effects.searchStringPublisher(searchText: searchString, using: environment.searchVideos)

            case .onLoadVideos(let videos):
                state.loading = .loaded
                state.videos = videos
                return .none

            case .onAppear:
                // TODO: load saved videos
                return .none

            case .onLoadVideosError(_):
                // TODO: present error to UI
                return .none
            }
        }
    }()
}

extension VideosListViewModel {
    struct Effects {
        static func searchStringPublisher(searchText: String, using client: SearchVideosClient) -> Effect<Action, Never> {
            client.videosMatching(searchText)
                .map(Action.onLoadVideos)
                .replaceError(with: .onLoadVideosError(.unknown))
                .eraseToAnyPublisher()
                .eraseToEffect()
        }
    }
}

extension VideosListViewModel.StoreType {
    static func create(
        initialState: VideosListViewModel.State = .init(),
        reducer: Reducer<VideosListViewModel.State, VideosListViewModel.Action, VideosListViewModel.Environment> = VideosListViewModel.reducer,
        environment: VideosListViewModel.Environment = .live
    ) -> Self {
        .init(initialState: initialState, reducer: reducer, environment: environment)
    }
}

extension VideosListViewModel {
    func viewModel(
        forDetailOf item: VideosListViewModel.VideoItem,
        environment: VideoDetailViewModel.Environment = .live
    ) -> VideoDetailViewModel {
        let detailStore: VideoDetailViewModel.StoreType =
            store.scope(
                toLocalState: { VideoDetailViewModel.StoreType.toLocalState(for: item, globalState: $0) },
                updateGlobalState: VideoDetailViewModel.StoreType.update(global:from:),
                environment: environment,
                using: VideoDetailViewModel.reducer
            )
        
        return .init(store: detailStore)
    }
}

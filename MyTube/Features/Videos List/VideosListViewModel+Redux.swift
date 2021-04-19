//
//  VideosListViewModel+Redux.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import Combine

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
        var videos: [Video]

        var likedVideoIDs: Set<String>

        init(loading: LoadingState = .idle, videos: [Video] = [], likedVideoIDs: Set<String> = []) {
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
        case onLoadVideos([Video])
        case onLoadVideosError(Error)
    }

    struct Environment {
        var searchVideos: SearchVideosUseCase
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

            case .onLoadVideosError(let error):
                state.loading = .error(error)
                return .none
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

extension VideosListViewModel.StoreType {
    static func create(
        initialState: VideosListViewModel.State = .init(),
        reducer: Reducer<VideosListViewModel.State, VideosListViewModel.Action, VideosListViewModel.Environment> = VideosListViewModel.reducer,
        environment: VideosListViewModel.Environment = .live
    ) -> Self {
        .init(initialState: initialState, reducer: reducer, environment: environment)
    }
}

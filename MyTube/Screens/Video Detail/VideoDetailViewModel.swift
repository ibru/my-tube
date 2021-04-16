//
//  VideoDetailViewModel.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

final class VideoDetailViewModel: ObservableObject {
    @Published var isLiked: Bool
    @Published var video: VideosListViewModel.VideoItem

    public var store: Store<State, Action>!

    init(store: Store<State, Action>) {
        self.store = store

        self.isLiked = store.state.isLiked
        self.video = store.state.video

        store.publisher.isLiked.assign(to: &self.$isLiked)
        store.publisher.video.assign(to: &self.$video)
    }

    func toggleLikeVideo() {
        if isLiked {
            store.send(.dislikeVideo)
        } else {
            store.send(.likeVideo)
        }
    }
}

extension VideoDetailViewModel {
    enum Error: Swift.Error, Equatable {
        case couldNotLikeVideo
        case couldNotDislikeVideo
    }

    struct State {
        let video: VideosListViewModel.VideoItem
        var isLiked: Bool
        var likeVideoError: Error?

        init(video: VideosListViewModel.VideoItem, isLiked: Bool, likeVideoError: Error? = nil) {
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
        var likeVideo: LikeVideoClient
    }
}

extension VideoDetailViewModel {
    static var reducer: Reducer<State, Action, Environment> = {
        Reducer<State, Action, Environment> { state, action, environment in
            switch action {
            case .likeVideo:
                return Effects.likeVideo(id: state.video.id, using: environment.likeVideo)

            case .dislikeVideo:
                return Effects.dislikeVideo(id: state.video.id, using: environment.likeVideo)

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
        static func likeVideo(id: String, using client: LikeVideoClient) -> Effect<Action, Never> {
            client.likeWithID(id)
                .map { _ in Action.videoLiked }
                .replaceError(with: .onLikeVideoError(.couldNotLikeVideo))
                .eraseToAnyPublisher()
                .eraseToEffect()
        }

        static func dislikeVideo(id: String, using client: LikeVideoClient) -> Effect<Action, Never> {
            client.dislikeWithID(id)
                .map { _ in Action.videoDisliked }
                .replaceError(with: .onLikeVideoError(.couldNotDislikeVideo))
                .eraseToAnyPublisher()
                .eraseToEffect()
        }
    }
}

extension VideoDetailViewModel.Environment {
    static var live: Self {
        .init(likeVideo: .live)
    }
}

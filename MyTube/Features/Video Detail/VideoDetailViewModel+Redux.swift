//
//  VideoDetailViewModel+Redux.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import Combine

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
            useCase.like(video)
                .map { _ in Action.videoLiked }
                .replaceError(with: .onLikeVideoError(.couldNotLikeVideo))
                .eraseToAnyPublisher()
                .eraseToEffect()
        }

        static func dislike(video: Video, using useCase: LikeVideoUseCase) -> Effect<Action, Never> {
            useCase.dislike(video)
                .map { _ in Action.videoDisliked }
                .replaceError(with: .onLikeVideoError(.couldNotDislikeVideo))
                .eraseToAnyPublisher()
                .eraseToEffect()
        }
    }
}

extension VideoDetailViewModel.Environment {
    static var live: Self {
        .init(
            likeVideo: .live(
                repository: .coreData(
                    repository: .live(
                        managedObjectContext: PersistenceController.shared.container.viewContext)
                )
            )
        )
    }
}

extension VideoDetailViewModel.StoreType {
    static func toLocalState(for selectedItem: Video, globalState: VideosListViewModel.State) -> (VideoDetailViewModel.State) {
        .init(video: selectedItem, isLiked: globalState.isLiked(videoId: selectedItem.id))
    }

    static func update(global: inout VideosListViewModel.State, from local: VideoDetailViewModel.State) {
        if local.isLiked {
            global.likedVideoIDs.insert(local.video.id)
        } else {
            global.likedVideoIDs.remove(local.video.id)
        }
    }
}


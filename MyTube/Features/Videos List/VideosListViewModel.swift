//
//  VideosListViewModel.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/26/21.
//

import Foundation
import Combine

final class VideosListViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var isSearching: Bool = false

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

        var likedVideoIDs: Set<String> = []

        store.publisher.videos
            .map {
                $0.map { video in
                    .init(video: video, isLiked: likedVideoIDs.contains(video.id))
                }
            }
            .assign(to: &self.$videos)

        store.publisher.searching
            .map {
                switch $0 {
                case .idle, .finished, .error(_):
                    return false
                case .searching(_):
                    return true
                }
            }
            .assign(to: &self.$isSearching)

        store.publisher.likedVideoIDs
            .sink { [unowned self] IDs in
                likedVideoIDs = IDs

                self.videos = self.videos
                    .map {
                        var updatedVideo = $0
                        updatedVideo.isLiked = IDs.contains($0.id)
                        return updatedVideo
                    }
            }
            .store(in: &bag)
    }

    deinit {
        bag.removeAll()
    }

    func viewAppeared() {
        store.send(.onAppear)
    }

    func searchVideos(for searchText: String) {
        store.send(.onSearch(searchText))
    }
}

extension VideosListViewModel {
    struct VideoItem: Equatable, Identifiable {
        var id: String { video.id }
        var title: String { video.title }
        var imageThumbnailUrl: URL? { video.imageThumbnailUrl }
        var isLiked: Bool

        fileprivate let video: Video

        init(video: Video) {
            self.video = video
            isLiked = false
        }

        init(video: Video, isLiked: Bool) {
            self.init(video: video)
            self.isLiked = isLiked
        }
    }
}

extension VideosListViewModel {
    func viewModel(
        forDetailOf item: VideosListViewModel.VideoItem,
        environment: VideoDetailViewModel.Environment = .live
    ) -> VideoDetailViewModel {
        let detailStore: VideoDetailViewModel.StoreType =
            store.scope(
                toLocalState: { VideoDetailViewModel.StoreType.toLocalState(for: item.video, globalState: $0) },
                updateGlobalState: VideoDetailViewModel.StoreType.update(global:from:),
                environment: environment,
                using: VideoDetailViewModel.reducer
            )

        return .init(store: detailStore)
    }
}

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
    @Published var isLoading: Bool = false

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

        store.publisher.videos
            .map { $0.map(VideoItem.init) }
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
    }

    deinit {
        bag.removeAll()
    }

    func isLiked(_ video: VideoItem) -> Bool {
        store.state.isLiked(videoId: video.id)
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

        fileprivate let video: Video

        init(video: Video) {
            self.video = video
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

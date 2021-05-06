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
    @Published var video: VideoItem

    private var store: StoreType

    init(store: StoreType) {
        self.store = store
        self.isLiked = store.state.isLiked
        self.video = VideoItem(video: store.state.video)

        store.publisher.isLiked
            .assign(to: &self.$isLiked)

        store.publisher.video
            .map(VideoItem.init)
            .assign(to: &self.$video)
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
    struct VideoItem: Equatable, Identifiable {
        let id: String
        let title: String
        let imageThumbnailUrl: URL?

        init(video: Video) {
            id = video.id
            title = video.title
            imageThumbnailUrl = video.imageThumbnailUrl
        }
    }
}

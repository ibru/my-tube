//
//  MyTubeApp.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/24/21.
//

import SwiftUI

@main
struct MyTubeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            VideosListView(
                viewModel: VideosListViewModel(
                    store: .videosList(
                        initialState: .init(
                            videos: [
                                .init(id: "123", title: "Video title", imageThumbnailUrl: nil),
                                .init(id: "456", title: "Video 2 title", imageThumbnailUrl: nil),
                                .init(id: "6789", title: "Video 3 title", imageThumbnailUrl: nil)
                            ]
                        )
                    )
                )
            )
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

extension Store {
    static func videosList(
        initialState: VideosListViewModel.State = .init(),
        reducer: Reducer<VideosListViewModel.State, VideosListViewModel.Action, VideosListViewModel.Environment> = VideosListViewModel.reducer,
        environment: VideosListViewModel.Environment = .live
    ) -> VideosListViewModel.StoreType {
        .init(initialState: initialState, reducer: reducer, environment: environment)
    }

    static func videoDetail(
        from videosListStore: VideosListViewModel.StoreType,
        for item: VideosListViewModel.VideoItem
    ) -> VideoDetailViewModel.StoreType {
        videosListStore.scope(
            toLocalState: {
                .init(video: item, isLiked: $0.isLiked(videoId: item.id))
            },
            updateGlobalState: { global, local in
                if local.isLiked {
                    global.likedVideoIDs.insert(local.video.id)
                } else {
                    global.likedVideoIDs.remove(local.video.id)
                }
            },
            environment: .live,
            using: VideoDetailViewModel.reducer
        )
    }
}

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
                    store: .create(
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

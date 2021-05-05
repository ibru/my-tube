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
                viewModel: VideosListViewModel(store: .create())
            )
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

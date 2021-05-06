//
//  Environments.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/6/21.
//

import Foundation

private let grdbPersistenceRepository: GRDBVideoPersistenceRepository = .live(
    createDatabase: { try .init(fileName: GRDBAppDatabase.defaultDBFileName) }
)

extension VideosListViewModel.Environment {
    static var live: Self {
        .init(
            mainQueue: .main,
            searchVideos: MyTube.live(
                repository: youTube(
                    apiFetcher: {
                        Endpoint.searchVideos(searchText: $0)
                            .send(environment: .searchMock)
                    }
                )
            ), loadSavedVideos: grdb(repository: grdbPersistenceRepository)
        )
    }
}

extension VideoDetailViewModel.Environment {
    static var live: Self {
        .init(
            likeVideo: .live(
                repository: .grdb(repository: grdbPersistenceRepository)
            )
        )
    }
}

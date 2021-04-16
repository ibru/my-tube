//
//  SearchVideosClient.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

struct SearchVideosClient {
    var videosMatching: (String) -> AnyPublisher<[VideosListViewModel.VideoItem], Error>
}

extension SearchVideosClient {
    static var live: Self {
        .init(
            videosMatching: {
                YoutubeVideosRepository().videos(for: $0)
                    .map {
                        $0.map {
                            .init(id: $0.id, title: $0.title, imageThumbnailUrl: $0.imageThumbnailUrl)
                        }
                    }
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
        )
    }
}

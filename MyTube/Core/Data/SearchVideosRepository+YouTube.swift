//
//  SearchVideosRepository+YouTube.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/30/21.
//

import Foundation
import Combine

typealias SearchYoutubeVideosAPI = (String) -> AnyPublisher<[YoutubeVideo], Networking.Error>

func youTube(apiFetcher: @escaping SearchYoutubeVideosAPI) -> SearchVideosRepository {
    {
        apiFetcher($0)
        .map {
            $0.map {
                .init(id: $0.id, title: $0.title, imageThumbnailUrl: $0.imageThumbnailUrl)
            }
        }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }
}

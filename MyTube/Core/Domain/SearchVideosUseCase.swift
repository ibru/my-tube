//
//  SearchVideosUseCase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

protocol SearchVideosUseCaseType {
    func videos(matching searchString: String) -> AnyPublisher<[Video], Error>
}

struct SearchVideosUseCase {}

extension SearchVideosUseCase: SearchVideosUseCaseType {
    func videos(matching searchString: String) -> AnyPublisher<[Video], Error> {
        YoutubeVideosRepository().videos(for: searchString)
            .map {
                $0.map {
                    .init(id: $0.id, title: $0.title, imageThumbnailUrl: $0.imageThumbnailUrl)
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

//
//  SearchVideosUseCase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

typealias SearchVideosUseCase = (String) -> AnyPublisher<[Video], Error>

typealias SearchVideosRepository = (String) -> AnyPublisher<[Video], Error>

func live(repository: @escaping SearchVideosRepository) -> SearchVideosUseCase {
    {
        repository($0)
    }
}

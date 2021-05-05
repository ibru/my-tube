//
//  LoadSavedVideosUseCase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/4/21.
//

import Foundation
import Combine

typealias LoadSavedVideosUseCase = () -> AnyPublisher<[Video], Error>

typealias LoadSavedVideosRepository = () -> AnyPublisher<[Video], Error>
//
//func live(repository: @escaping LoadSavedVideosRepository) -> LoadSavedVideosUseCase {
//    {
//        repository()
//            .receive(on: DispatchQueue.main)
//            .eraseToAnyPublisher()
//    }
//}

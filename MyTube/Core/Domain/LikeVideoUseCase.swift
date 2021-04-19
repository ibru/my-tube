//
//  LikeVideoUseCase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

struct LikeVideoUseCase {
    var likeWithID: (String) -> AnyPublisher<Bool, Error>
    var dislikeWithID: (String) -> AnyPublisher<Bool, Error>
}

extension LikeVideoUseCase {
    static var live: Self {
        .init(
            likeWithID: { _ in
                Just(true)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }, dislikeWithID: { _ in
                Just(true)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        )
    }
}

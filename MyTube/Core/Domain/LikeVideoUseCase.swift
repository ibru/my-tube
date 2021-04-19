//
//  LikeVideoUseCase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

struct LikeVideoUseCase {
    var like: (Video) -> AnyPublisher<Bool, Error>
    var dislike: (Video) -> AnyPublisher<Bool, Error>
}

extension LikeVideoUseCase {
    static var live: Self {
        .init(
            like: { _ in
                Just(true)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }, dislike: { _ in
                Just(true)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        )
    }
}

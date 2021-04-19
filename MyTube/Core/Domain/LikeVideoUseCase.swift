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

struct LikeVideoRepository {
    var like: (Video) -> AnyPublisher<Bool, Error>
    var dislike: (Video) -> AnyPublisher<Bool, Error>
}

extension LikeVideoUseCase {
    static func live(repository: LikeVideoRepository) -> Self {
        .init(like: repository.like, dislike: repository.dislike)
    }
}

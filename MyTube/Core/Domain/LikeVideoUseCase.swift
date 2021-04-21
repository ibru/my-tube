//
//  LikeVideoUseCase.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/16/21.
//

import Foundation
import Combine

protocol LikeVideoUseCaseType {
    func like(_ video: Video) -> AnyPublisher<Bool, Error>
    func dislike(_ video: Video) -> AnyPublisher<Bool, Error>
}

protocol LikeVideoRepositoryType {
    func like(_ video: Video) -> AnyPublisher<Bool, Error>
    func dislike(_ video: Video) -> AnyPublisher<Bool, Error>
}

struct LikeVideoUseCase {
    private var likeVideoRepository: LikeVideoRepositoryType

    init(repository: LikeVideoRepositoryType) {
        self.likeVideoRepository = repository
    }
}

extension LikeVideoUseCase: LikeVideoUseCaseType {
    func like(_ video: Video) -> AnyPublisher<Bool, Error> {
        likeVideoRepository.like(video)
    }

    func dislike(_ video: Video) -> AnyPublisher<Bool, Error> {
        likeVideoRepository.dislike(video)
    }
}

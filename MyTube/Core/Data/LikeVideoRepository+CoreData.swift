//
//  LikeVideoRepository+CoreData.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import Combine

struct CoreDataLikeVideoRepository {
    private var repository: CoreDataVideoPersistenceRepositoryType

    init(repository: CoreDataVideoPersistenceRepositoryType) {
        self.repository = repository
    }
}

extension CoreDataLikeVideoRepository: LikeVideoRepositoryType {
    func like(_ video: Video) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { promise in
                do {
                    try repository.saveVideo(video)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func dislike(_ video: Video) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { promise in
                do {
                    try repository.deleteVideo(video)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

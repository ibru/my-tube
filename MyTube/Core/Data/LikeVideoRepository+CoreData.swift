//
//  LikeVideoRepository+CoreData.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import Combine

extension LikeVideoRepository {
    static func coreData(repository: CoreDataVideoPersistenceRepository) -> Self {
        .init(
            like: { video in
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
            },
            dislike: { video in
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
        )
    }
}

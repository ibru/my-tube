//
//  LikeVideoRepository+GRDB.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/5/21.
//

import Foundation
import Combine

extension LikeVideoRepository {
    static func grdb(repository: GRDBVideoPersistenceRepository) -> Self {
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

extension GRDBVideo {
    init(video: Video, saveDate: Date) {
        self.videoID = video.id
        self.title = video.title
        self.imageThumbnailURL = video.imageThumbnailUrl
        self.dateSaved = saveDate
    }
}

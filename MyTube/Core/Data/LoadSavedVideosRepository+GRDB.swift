//
//  LoadSavedVideosRepository+GRDB.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/5/21.
//

import Foundation
import Combine

func grdb(repository: GRDBVideoPersistenceRepository) -> LoadSavedVideosRepository {
    {
        do {
            let videos = try repository.savedVideos()
            return Just(videos)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}

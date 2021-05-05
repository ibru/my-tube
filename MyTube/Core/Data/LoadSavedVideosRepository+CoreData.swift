//
//  LoadSavedVideosRepository+CoreData.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/5/21.
//

import Foundation
import Combine

func coreData(persistor: CoreDataVideoPersistenceRepository) -> LoadSavedVideosRepository {
    {
        do {
            let videos = try persistor.savedVideos()
            return Just(videos)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}


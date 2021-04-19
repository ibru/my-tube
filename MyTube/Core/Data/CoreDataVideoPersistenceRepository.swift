//
//  CoreDataVideoPersistenceRepository.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import CoreData

struct CoreDataVideoPersistenceRepository {
    var saveVideo: (Video) throws -> Void
    var deleteVideo: (Video) throws -> Void
    var savedVideos: () throws -> [Video]

    init(
        saveVideo: @escaping (Video) throws -> Void,
        deleteVideo: @escaping (Video) throws -> Void,
        savedVideos: @escaping () throws -> [Video]
    ) {
        self.saveVideo = saveVideo
        self.deleteVideo = deleteVideo
        self.savedVideos = savedVideos
    }
}

extension CoreDataVideoPersistenceRepository {
    static func live(managedObjectContext: NSManagedObjectContext) -> Self {
        .init(
            saveVideo: { video in
                let savedVideo = CDVideo(context: managedObjectContext)
                savedVideo.id = video.id
                savedVideo.title = video.title
                savedVideo.thumbnailUrl = video.imageThumbnailUrl?.absoluteString
                savedVideo.dateSaved = .init()

                try managedObjectContext.save()
            },
            deleteVideo: { video in
                let fetchRequest: NSFetchRequest<CDVideo> = CDVideo.fetchRequest()
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "id", ascending: true)
                ]
                fetchRequest.predicate = .init(format: "id == \(video.id)")

                let videos = try managedObjectContext.fetch(fetchRequest)
                videos.forEach {
                    managedObjectContext.delete($0)
                }

                try managedObjectContext.save()
            },
            savedVideos: {
                let fetchRequest: NSFetchRequest<CDVideo> = CDVideo.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSaved", ascending: true)]
                
                let videos = try managedObjectContext.fetch(fetchRequest)

                return videos.compactMap {
                    guard let id = $0.id, let title = $0.title else {
                        return nil
                    }

                    return .init(
                        id: id,
                        title: title,
                        imageThumbnailUrl: $0.thumbnailUrl.map { URL(string: $0) } ?? nil
                    )
                }
            }
        )
    }
}

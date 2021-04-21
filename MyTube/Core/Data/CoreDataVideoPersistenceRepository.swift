//
//  CoreDataVideoPersistenceRepository.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import CoreData

protocol CoreDataVideoPersistenceRepositoryType {
    func saveVideo(_ video: Video) throws
    func deleteVideo(_ video: Video) throws
    func savedVideos() throws -> [Video]
}

struct CoreDataVideoPersistenceRepository {
    private let  managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
}

extension CoreDataVideoPersistenceRepository: CoreDataVideoPersistenceRepositoryType {
    func saveVideo(_ video: Video) throws {
        let savedVideo = CDVideo(context: managedObjectContext)
        savedVideo.id = video.id
        savedVideo.title = video.title
        savedVideo.thumbnailUrl = video.imageThumbnailUrl?.absoluteString
        savedVideo.dateSaved = .init()

        try managedObjectContext.save()
    }

    func deleteVideo(_ video: Video) throws {
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
    }

    func savedVideos() throws -> [Video] {
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
}

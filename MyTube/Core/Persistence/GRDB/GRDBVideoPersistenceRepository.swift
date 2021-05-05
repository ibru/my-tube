//
//  GRDBVideoPersistenceRepository.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/5/21.
//

import Foundation
import GRDB

struct GRDBVideoPersistenceRepository {
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

extension GRDBVideoPersistenceRepository {
    static func live(dbReader: DatabaseReader, dbWriter: DatabaseWriter) -> Self {
        .init(
            saveVideo: { video in
                var grdbVideo = GRDBVideo(video: video, saveDate: .init())

                if grdbVideo.title.isEmpty {
                    throw GRDBAppDatabase.ValidationError.missingRequiredField("title")
                }
                if grdbVideo.videoID.isEmpty {
                    throw GRDBAppDatabase.ValidationError.missingRequiredField("videoID")
                }
                try dbWriter.write { db in
                    try grdbVideo.save(db)
                }
            },
            deleteVideo: { video in
                try dbWriter.write { db in
                    _ = try GRDBVideo.deleteOne(db, key: ["videoID": video.id])
                }
            },
            savedVideos: {
                try dbReader.read { db in
                    try GRDBVideo.all().orderedBySaveDate().fetchAll(db)
                }
                .map {
                    .init(id: $0.videoID, title: $0.title, imageThumbnailUrl: $0.imageThumbnailURL) }
            }
        )
    }
}

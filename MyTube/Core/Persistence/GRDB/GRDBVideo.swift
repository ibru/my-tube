//
//  GRDBVideo.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/5/21.
//

import Foundation
import GRDB

public struct GRDBVideo {
    private var id: Int64?
    public let videoID: String
    public let title: String
    public let dateSaved: Date
    public let imageThumbnailURL: URL?
}

extension GRDBVideo: Codable, FetchableRecord, TableRecord, MutablePersistableRecord {
    fileprivate enum Columns {
        static let videoID = Column(CodingKeys.videoID)
        static let title = Column(CodingKeys.title)
        static let dateSaved = Column(CodingKeys.dateSaved)
        static let imageThumbnailURL = Column(CodingKeys.imageThumbnailURL)
    }

    public static var databaseTableName: String = "videos"
    
    /// Updates a player id after it has been inserted in the database.
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

extension DerivableRequest where RowDecoder == GRDBVideo {
    func orderedByTitle() -> Self {
        order(GRDBVideo.Columns.title.collating(.localizedCaseInsensitiveCompare))
    }

    func orderedBySaveDate() -> Self {
        order(GRDBVideo.Columns.dateSaved.desc)
    }
}

//
//  GRDBVideoPersistenceRepositoryTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/5/21.
//

import XCTest
@testable import MyTube
import GRDB

class GRDBVideoPersistenceRepositoryTests: XCTestCase {
    func testsSaveVideoShouldThrowErrorWhenVideoIDIsEmpty() throws {
        let dbQueue = DatabaseQueue()
        let appDatabase = try GRDBAppDatabase(dbQueue)
        let video = Video(id: "", title: "title", imageThumbnailUrl: nil)

        let repository = GRDBVideoPersistenceRepository.live(
            dbReader: appDatabase.dbReader,
            dbWriter: appDatabase.dbWriter
        )

        XCTAssertThrowsError(try repository.saveVideo(video), "") { error in
            XCTAssertEqual(error as? GRDBAppDatabase.ValidationError, .missingRequiredField("videoID"))
        }
    }
}

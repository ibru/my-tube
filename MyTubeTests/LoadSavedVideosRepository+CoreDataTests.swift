//
//  LoadSavedVideosRepository+CoreDataTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/5/21.
//

import XCTest
@testable import MyTube
import CombineExpectations

class LoadSavedVideosRepositoryCoreDataTests: XCTestCase {
    func testShouldReturnResultFromSavedVideos() throws {
        let videos: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let persistor = CoreDataVideoPersistenceRepository(
            saveVideo: { _ in XCTFail("Should not call save video") },
            deleteVideo: { _ in XCTFail("Should not call delete video") },
            savedVideos: { videos }
        )
        let repository = coreData(persistor: persistor)

        let actualVideos = try repository()
            .record()
            .single
            .get()

        XCTAssertEqual(actualVideos, videos)
    }
}

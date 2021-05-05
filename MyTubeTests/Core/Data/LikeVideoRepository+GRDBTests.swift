//
//  LikeVideoRepository+GRDBTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/5/21.
//

import XCTest
@testable import MyTube

class LikeVideoRepositoryGRDBTests: XCTestCase {
    func testLikeShouldCallSaveMethod() throws {
        let exp = expectation(description: "Save method called")
        let repository = GRDBVideoPersistenceRepository(
            saveVideo: { video in
                exp.fulfill()
            },
            deleteVideo: { _ in
                XCTFail("Should not call delete video")
            }, savedVideos: { [] }
        )

        let likeRepository = LikeVideoRepository.grdb(repository: repository)

        let recorder = likeRepository.like(.mock())
            .record()
            .next()

        _ = try wait(for: recorder, timeout: 0.1)
        waitForExpectations(timeout: 0.15)
    }
}

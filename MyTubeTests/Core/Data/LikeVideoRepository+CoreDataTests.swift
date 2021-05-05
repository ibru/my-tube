//
//  LikeVideoRepository+CoreDataTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 4/19/21.
//

import XCTest
@testable import MyTube
import CombineExpectations

class LikeVideoRepositoryCoreDataTests: XCTestCase {

    func testLikeShouldCallSaveMethod() throws {
        let exp = expectation(description: "Save method called")
        let repository = CoreDataVideoPersistenceRepository(
            saveVideo: { video in
                exp.fulfill()
            },
            deleteVideo: { _ in
                XCTFail("Should not call delete video")
            }, savedVideos: { [] }
        )

        let likeRepository = LikeVideoRepository.coreData(repository: repository)

        let recorder = likeRepository.like(.mock())
            .record()
            .next()

        _ = try wait(for: recorder, timeout: 0.1)
        waitForExpectations(timeout: 0.15)
    }
}

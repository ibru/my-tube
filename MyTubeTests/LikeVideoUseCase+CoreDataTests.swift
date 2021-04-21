//
//  LikeVideoUseCase+CoreDataTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 4/19/21.
//

import XCTest
@testable import MyTube
import CombineExpectations

class LikeVideoUseCaseCoreDataTests: XCTestCase {

    func testLikeShouldCallSaveMethod() throws {
        let persistenceRepository = CoreDataVideoPersistenceRepositorySpy()
        let repository = CoreDataLikeVideoRepository(repository: persistenceRepository)

        let recorder = repository.like(.mock())
            .record()
            .next()

        _ = try wait(for: recorder, timeout: 0.1)

        XCTAssertTrue(persistenceRepository.saveVideoCalled)
        XCTAssertFalse(persistenceRepository.deleteVideoCalled)
    }
}

class CoreDataVideoPersistenceRepositorySpy: CoreDataVideoPersistenceRepositoryType {
    var saveVideoCalled = false
    var deleteVideoCalled = false

    func saveVideo(_ video: Video) throws {
        saveVideoCalled = true
    }

    func deleteVideo(_ video: Video) throws {
        deleteVideoCalled = true
    }

    func savedVideos() throws -> [Video] {
        []
    }
}

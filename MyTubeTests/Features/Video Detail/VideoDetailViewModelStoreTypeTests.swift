//
//  VideoDetailViewModelStoreTypeTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 4/18/21.
//

import XCTest
@testable import MyTube

class VideoDetailViewModelStoreTypeTests: XCTestCase {

    func testLikeVideoInsideLocalStateShouldAddVideoIdToLikedVideoIDsInsideGlobalState() {
        let localState: VideoDetailViewModel.State = .mock(video: .mock(id: "id1"), isLiked: true)
        var globalState: VideosListViewModel.State = .init(likedVideoIDs: ["id0"])

        VideoDetailViewModel.StoreType.update(global: &globalState, from: localState)
        XCTAssertEqual(globalState.likedVideoIDs, ["id0", "id1"])
    }

    func testDislikeVideoInsideLocalStateShouldRemoveVideoIdFromLikedVideoIDsInsideGlobalState() {
        let localState: VideoDetailViewModel.State = .mock(video: .mock(id: "id1"), isLiked: false)
        var globalState: VideosListViewModel.State = .init(likedVideoIDs: ["id1", "id2"])

        VideoDetailViewModel.StoreType.update(global: &globalState, from: localState)
        XCTAssertEqual(globalState.likedVideoIDs, ["id2"])
    }

    func testRecognizeSelectedVideoIsLiked() {
        let globalState: VideosListViewModel.State = .init(likedVideoIDs: ["id1", "id2"])
        let localState = VideoDetailViewModel.StoreType.toLocalState(for: .mock(id: "id1"), globalState: globalState)
        XCTAssertTrue(localState.isLiked)
    }

    func testRecoginzeSelectedVideoIsNotLiked() {
        let globalState: VideosListViewModel.State = .init(likedVideoIDs: ["id1", "id2"])
        let localState = VideoDetailViewModel.StoreType.toLocalState(for: .mock(id: "id3"), globalState: globalState)
        XCTAssertFalse(localState.isLiked)
    }
}

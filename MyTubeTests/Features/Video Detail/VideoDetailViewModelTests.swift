//
//  VideoDetailViewModelTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 4/17/21.
//

import XCTest
@testable import MyTube
import Combine

class VideoDetailViewModelTests: XCTestCase {
    func makeViewModel(
        initialState: VideoDetailViewModel.State,
        environment: VideoDetailViewModel.Environment
    ) -> VideoDetailViewModel {
        let store = Store<VideoDetailViewModel.State, VideoDetailViewModel.Action>(
            initialState: initialState,
            reducer: VideoDetailViewModel.reducer,
            environment: environment
        )
        return .init(store: store)
    }

    func testIsLikedShouldReturnTrueWhenVideoIsLikedInitially() {
        let state: VideoDetailViewModel.State = .mock(isLiked: true)
        let viewModel = makeViewModel(initialState: state, environment: .noop)

        XCTAssertTrue(viewModel.isLiked)
    }

    func testIsLikedShouldReturnFalseWhenVideoIsNotLikedInitially() {
        let state: VideoDetailViewModel.State = .mock(isLiked: false)
        let viewModel = makeViewModel(initialState: state, environment: .noop)

        XCTAssertFalse(viewModel.isLiked)
    }

    func testToggleLikeVideoShouldLikeVideoWhenVideoIsNotLiked() {
        let state: VideoDetailViewModel.State = .mock(video: .mock(id: "id1"), isLiked: false)
        let exp = expectation(description: "Like video called")

        var environment: VideoDetailViewModel.Environment = .noop
        environment.likeVideo.like = {
            XCTAssertEqual($0.id, "id1")
            exp.fulfill()
            return .just(true)
        }
        environment.likeVideo.dislike = { _ in
            XCTFail("Should not dislike video")
            return .just(true)
        }

        let viewModel = makeViewModel(initialState: state, environment: environment)

        viewModel.toggleLikeVideo()

        waitForExpectations(timeout: 0.1)
    }

    func testToggleLikeVideoShouldDislikeVideoWhenVideoIsLiked() {
        let state: VideoDetailViewModel.State = .mock(video: .mock(id: "id1"), isLiked: true)
        let exp = expectation(description: "Dislike video called")

        var environment: VideoDetailViewModel.Environment = .noop
        environment.likeVideo.like = { _ in
            XCTFail("Should not like video")
            return .just(true)
        }
        environment.likeVideo.dislike = {
            XCTAssertEqual($0.id, "id1")
            exp.fulfill()
            return .just(true)
        }

        let viewModel = makeViewModel(initialState: state, environment: environment)

        viewModel.toggleLikeVideo()

        waitForExpectations(timeout: 0.1)
    }
}

private extension VideoDetailViewModel.Environment {
    static var noop: Self {
        return .init(
            likeVideo: LikeVideoUseCase(
                like: { _ in .empty() },
                dislike: { _ in .empty() }
            )
        )
    }
}

extension VideoDetailViewModel.State {
    static func mock(
        video: Video = .mock(),
        isLiked: Bool = false
    ) -> Self {
        .init(video: video, isLiked: isLiked)
    }
}

extension Video {
    static func mock(
        id: String = "mockId",
        title: String = "Mock video",
        imageThumbnailUrl: URL? = nil
    ) -> Self {
        .init(id: id, title: title, imageThumbnailUrl: imageThumbnailUrl)
    }
}

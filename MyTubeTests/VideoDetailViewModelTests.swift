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

        let likeVideoUseCase = LikeVideoUseCaseSpy(likePublisher: .just(true), dislikePublisher: .just(true))
        var environment: VideoDetailViewModel.Environment = .noop
        environment.likeVideo = likeVideoUseCase

        let viewModel = makeViewModel(initialState: state, environment: environment)

        viewModel.toggleLikeVideo()

        XCTAssertTrue(likeVideoUseCase.likeVideoCalled)
        XCTAssertEqual(likeVideoUseCase.givenVideo?.id, "id1")
        XCTAssertFalse(likeVideoUseCase.dislikeVideoCalled)
    }

    func testToggleLikeVideoShouldDislikeVideoWhenVideoIsLiked() {
        let state: VideoDetailViewModel.State = .mock(video: .mock(id: "id1"), isLiked: true)

        let likeVideoUseCase = LikeVideoUseCaseSpy(likePublisher: .just(true), dislikePublisher: .just(true))
        var environment: VideoDetailViewModel.Environment = .noop
        environment.likeVideo = likeVideoUseCase

        let viewModel = makeViewModel(initialState: state, environment: environment)

        viewModel.toggleLikeVideo()

        XCTAssertFalse(likeVideoUseCase.likeVideoCalled)
        XCTAssertTrue(likeVideoUseCase.dislikeVideoCalled)
        XCTAssertEqual(likeVideoUseCase.givenVideo?.id, "id1")
    }
}

private extension VideoDetailViewModel.Environment {
    static var noop: Self {
        return .init(
            likeVideo: LikeVideoUseCaseStub(likePublisher: .empty(), dislikePublisher: .empty())
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

class LikeVideoUseCaseStub: LikeVideoUseCaseType {
    var likePublisher: AnyPublisher<Bool, Error>
    var dislikePublisher: AnyPublisher<Bool, Error>

    init(likePublisher: AnyPublisher<Bool, Error>, dislikePublisher: AnyPublisher<Bool, Error>) {
        self.likePublisher = likePublisher
        self.dislikePublisher = dislikePublisher
    }

    func like(_ video: Video) -> AnyPublisher<Bool, Error> {
        likePublisher
    }

    func dislike(_ video: Video) -> AnyPublisher<Bool, Error> {
        dislikePublisher
    }
}

class LikeVideoUseCaseSpy: LikeVideoUseCaseStub {
    var likeVideoCalled = false
    var dislikeVideoCalled = false
    var givenVideo: Video?

    override func like(_ video: Video) -> AnyPublisher<Bool, Error> {
        likeVideoCalled = true
        givenVideo = video
        return super.like(video)
    }

    override func dislike(_ video: Video) -> AnyPublisher<Bool, Error> {
        dislikeVideoCalled = true
        givenVideo = video
        return super.dislike(video)
    }
}

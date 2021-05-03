//
//  VideosListViewModelTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 1/26/21.
//

import XCTest
@testable import MyTube
import Combine
import CombineExpectations

class VideosListViewModelTests: XCTestCase {

    private var bag = Set<AnyCancellable>()

    func testShouldStartEmpty() {
        let viewModel = VideosListViewModel()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.videos, [])
    }

    func testSearchVideosShouldPassSearchedStringToSearchVideosUseCase() {
        var actualSearchString = ""
        let environment = VideosListViewModel.Environment(searchVideos: {
            actualSearchString = $0
            return .just([])
        })

        let viewModel = VideosListViewModel(environment: environment)
        let expectedSearchString = "search"

        viewModel.searchVideos(for: expectedSearchString)

        XCTAssertEqual(actualSearchString, expectedSearchString)
    }

    func testSearchVideosShouldLoadVideosUsingSearchVideosUseCase() throws {
        let videos: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let viewModel = VideosListViewModel(environment: .mock(with: videos))

        let recorder = viewModel.$videos
            .dropFirst()
            .record()
            .next()

        viewModel.searchVideos(for: "search")

        let items = try wait(for: recorder, timeout: 0.20)
        let expectedItems = videos.map(VideosListViewModel.VideoItem.init)

        XCTAssertEqual([items], [expectedItems])
    }

    func testSearchVideosShouldChangeIsLoadingToTrueWhenVideosMatchingUseCaseIsNotCompletedYet() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(reducer: VideosListViewModel.reducer, environment: environment)

        viewModel.searchVideos(for: "search")
        XCTAssertTrue(viewModel.isLoading)
    }

    func testSearchVideosShouldChangeIsLoadingToFalseWhenVideosMatchingUseCaseProducesAnyOutput() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")
        loadedVideosSubject.send([])

        XCTAssertFalse(viewModel.isLoading)
    }

    func testSearchVideosShouldChangeIsLoadingToFalseWhenVideosMatchingUseCaseCompletesWithError() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        let error: Error = NSError()

        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")
        loadedVideosSubject.send(completion: .failure(error))

        XCTAssertFalse(viewModel.isLoading)
    }

    func testSearchVideosShouldSetIsLoadingToTrueWhenVideosMatchingUseCaseIsLoadingVideos() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")

        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testSearchVideosShouldReplaceResultsFromPreviousSearch() throws {
        var loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let videos1: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let videos2: [Video] = [
            .init(id: "id3", title: "Video 3", imageThumbnailUrl: nil),
            .init(id: "id4", title: "Video 4", imageThumbnailUrl: URL(string: "http://example.com"))
        ]

        let viewModel = VideosListViewModel(environment: environment)

        let recorder = viewModel.$videos
            .dropFirst()
            .record()
            .next(2)

        viewModel.searchVideos(for: "search1")
        loadedVideosSubject.send(videos1)
        loadedVideosSubject.send(completion: .finished)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadedVideosSubject = PassthroughSubject<[Video], Error>()
            viewModel.searchVideos(for: "search2")
            loadedVideosSubject.send(videos2)
            loadedVideosSubject.send(completion: .finished)
        }

        let items = try wait(for: recorder, timeout: 0.20)

        let expectedItems: [[VideosListViewModel.VideoItem]] = [
            videos1.map(VideosListViewModel.VideoItem.init),
            videos2.map(VideosListViewModel.VideoItem.init)
        ]

        XCTAssertEqual(items, expectedItems)
    }

    func testVideosShouldTellWhichVideoIsLiked() {
        let state: VideosListViewModel.State = .init(
            loading:.loaded,
            videos: [.mock(id: "id1"), .mock(id: "id2"), .mock(id: "id3")],
            likedVideoIDs: ["id2"]
        )
        let viewModel = VideosListViewModel(initialState: state, environment: .dummy)

        let likes = viewModel.videos.reduce(into: [:]) { $0[$1.id] = $1.isLiked }
        XCTAssertEqual(likes, ["id1": false, "id2": true, "id3": false])
    }

    func testReduceShouldChangeStateFromIdleToLoadingWhenItReceivesOnSearchEvent() {
        let searchString = "search"
        var state: VideosListViewModel.State = .init(loading:.idle, videos: [])

        _ = VideosListViewModel.reducer.run(&state, .onSearch(searchString), .dummy)

        XCTAssertEqual(state, .init(loading: .loading(searchString), videos: []))
    }
}


private extension VideosListViewModel.Environment {
    static var dummy: Self {
        return .mock(with: [])
    }

    static var noop: Self {
        return .mock(with: [])
    }

    static func mock(with videos: [Video]) -> Self {
        .init(
            searchVideos: { _ in .just(videos) }
        )
    }
}

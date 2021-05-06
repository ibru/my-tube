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

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(viewModel.videos, [])
    }

    func testSearchVideosShouldPassSearchedStringToSearchVideosUseCase() {
        var actualSearchString = ""
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = {
            actualSearchString = $0
            return .just([])
        }

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
        let viewModel = VideosListViewModel(environment: .mock(searchedVideos: videos))

        let recorder = viewModel.$videos
            .dropFirst()
            .record()
            .next()

        viewModel.searchVideos(for: "search")

        let items = try wait(for: recorder, timeout: 0.20)
        let expectedItems = videos.map(VideosListViewModel.VideoItem.init)

        XCTAssertEqual([items], [expectedItems])
    }

    func testSearchVideosShouldChangeIsSearchingToTrueWhenVideosMatchingUseCaseIsNotCompletedYet() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(reducer: VideosListViewModel.reducer, environment: environment)

        viewModel.searchVideos(for: "search")
        XCTAssertTrue(viewModel.isSearching)
    }

    func testSearchVideosShouldChangeIsSearchingToFalseWhenVideosMatchingUseCaseProducesAnyOutput() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")
        loadedVideosSubject.send([])

        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchVideosShouldChangeIsSearchingToFalseWhenVideosMatchingUseCaseCompletesWithError() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        let error: Error = NSError()

        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")
        loadedVideosSubject.send(completion: .failure(error))

        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchVideosShouldSetIsSearchingToTrueWhenVideosMatchingUseCaseIsLoadingVideos() {
        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = { _ in loadedVideosSubject.eraseToAnyPublisher() }

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")

        XCTAssertTrue(viewModel.isSearching)
    }
    
    func testSearchVideosShouldReplaceResultsFromPreviousSearch() {
        var loadedVideosSubject = PassthroughSubject<[Video], Error>()
        let mainQueue = DispatchQueue.test
        var environment = VideosListViewModel.Environment.noop
        environment.mainQueue = mainQueue.eraseToAnyScheduler()
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

        mainQueue.schedule(after: mainQueue.now.advanced(by: 1)) {
            loadedVideosSubject.send(videos1)
            loadedVideosSubject.send(completion: .finished)
        }
        mainQueue.schedule(after: mainQueue.now.advanced(by: 2)) {
            loadedVideosSubject = PassthroughSubject<[Video], Error>()
            viewModel.searchVideos(for: "search2")
        }
        mainQueue.schedule(after: mainQueue.now.advanced(by: 3)) {
            loadedVideosSubject.send(videos2)
            loadedVideosSubject.send(completion: .finished)
        }

        viewModel.searchVideos(for: "search1")

        XCTAssertEqual(viewModel.videos.count, 0)
        XCTAssertTrue(viewModel.isSearching)

        mainQueue.advance(by: 1)
        XCTAssertEqual(viewModel.videos, videos1.map(VideosListViewModel.VideoItem.init))
        XCTAssertFalse(viewModel.isSearching)

        mainQueue.advance(by: 1)
        XCTAssertEqual(viewModel.videos, videos1.map(VideosListViewModel.VideoItem.init))
        XCTAssertTrue(viewModel.isSearching)

        mainQueue.advance(by: 1)
        XCTAssertEqual(viewModel.videos, videos2.map(VideosListViewModel.VideoItem.init))
        XCTAssertFalse(viewModel.isSearching)
    }

    func testVideosShouldTellWhichVideoIsLiked() {
        let state: VideosListViewModel.State = .init(
            searching: .finished,
            videos: [.mock(id: "id1"), .mock(id: "id2"), .mock(id: "id3")],
            likedVideoIDs: ["id2"]
        )
        let viewModel = VideosListViewModel(initialState: state, environment: .noop)

        let likes = viewModel.videos.reduce(into: [:]) { $0[$1.id] = $1.isLiked }
        XCTAssertEqual(likes, ["id1": false, "id2": true, "id3": false])
    }

    func testReducerShouldChangeSearchingStateFromIdleToLoadingWhenItReceivesOnSearchEvent() {
        let searchString = "search"
        var state: VideosListViewModel.State = .init(searching: .idle, videos: [])

        _ = VideosListViewModel.reducer.run(&state, .onSearch(searchString), .noop)

        XCTAssertEqual(state, .init(searching: .searching(searchString), videos: []))
    }

    func testViewAppearedShouldLoadSavedVideosUsingLoadSavedVideosUC() throws {
        let videos: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let environment = VideosListViewModel.Environment.mock(savedVideos: videos)

        let viewModel = VideosListViewModel(
            initialState: .init(locallyLoading: .idle, videos: []),
            environment: environment
        )

        viewModel.viewAppeared()

        let expectedItems = videos.map {
            VideosListViewModel.VideoItem.init(video: $0, isLiked: true)
        }
        XCTAssertEqual(viewModel.videos, expectedItems)
    }

    func testSearchVideosShouldMarkSearchedVideoLikedWhenItWasSavedLocallyBefore() throws {
        let savedVideos: [Video] = [
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let searchedVideos: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com")),
            .init(id: "id3", title: "Video 3", imageThumbnailUrl: nil)
        ]

        let environment = VideosListViewModel.Environment.mock(savedVideos: savedVideos, searchedVideos: searchedVideos)

        let viewModel = VideosListViewModel(
            initialState: .init(searching: .idle, videos: []),
            environment: environment
        )

        viewModel.viewAppeared()
        viewModel.searchVideos(for: "dummy")

        let items = viewModel.videos
        let likes = items.reduce(into: [:]) { $0[$1.id] = $1.isLiked }
        XCTAssertEqual(likes, ["id1": false, "id2": true, "id3": false])
    }
}

extension VideosListViewModel.Environment {
    static func mock(savedVideos: [Video] = [], searchedVideos: [Video] = []) -> Self {
        .init(
            mainQueue: .immediate,
            searchVideos: { _ in .just(searchedVideos) },
            loadSavedVideos: { .just(savedVideos) }
        )
    }
}

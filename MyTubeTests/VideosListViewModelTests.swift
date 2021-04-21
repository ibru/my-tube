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

    func testSearchForShouldPassSearchedStringToSearchVideosUseCase() throws {
        let searchVideosUseCase = SearchVideosUseCaseSpy()
        let environment = VideosListViewModel.Environment(searchVideos: searchVideosUseCase)

        let viewModel = VideosListViewModel(environment: environment)
        let expectedSearchString = "search"

        let recorder = viewModel.$videos
            .record()
            .next(1)

        viewModel.searchVideos(for: expectedSearchString)

        _ = try wait(for: recorder, timeout: 0.20)

        XCTAssertEqual(searchVideosUseCase.givenSearchString, expectedSearchString)
    }

    func testSearchVideosShouldLoadVideosUsingSearchVideosUseCase() throws {
        let videos: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let searchVideosUseCase = SearchVideosUseCaseStub()
        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = searchVideosUseCase

        let viewModel = VideosListViewModel(environment: environment)

        let recorder = viewModel.$videos
            .dropFirst()
            .record()
            .next()

        viewModel.searchVideos(for: "search")
        searchVideosUseCase.loadedVideosSubject.send(videos)

        let items = try wait(for: recorder, timeout: 0.20)
        let expectedItems = videos.map(VideosListViewModel.VideoItem.init)

        XCTAssertEqual([items], [expectedItems])
    }

    func testSearchVideosShouldChangeIsLoadingToTrueWhenVideosMatchingUseCaseIsNotCompletedYet() {
        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = SearchVideosUseCaseStub()

        let viewModel = VideosListViewModel(reducer: VideosListViewModel.reducer, environment: environment)

        viewModel.searchVideos(for: "search")
        XCTAssertTrue(viewModel.isLoading)
    }

    func testSearchVideosShouldChangeIsLoadingToFalseWhenVideosMatchingUseCaseProducesAnyOutput() {
        let searchVideosUseCase = SearchVideosUseCaseStub()
        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = searchVideosUseCase

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")
        searchVideosUseCase.loadedVideosSubject.send([])

        XCTAssertFalse(viewModel.isLoading)
    }

    func testSearchVideosShouldChangeIsLoadingToFalseWhenVideosMatchingUseCaseCompletesWithError() {
        let error: Error = NSError()
        let searchVideosUseCase = SearchVideosUseCaseStub()
        var environment = VideosListViewModel.Environment.dummy
        environment.searchVideos = searchVideosUseCase

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")
        searchVideosUseCase.loadedVideosSubject.send(completion: .failure(error))

        XCTAssertFalse(viewModel.isLoading)
    }

    func testSearchVideosShouldSetIsLoadingToTrueWhenVideosMatchingUseCaseIsLoadingVideos() {
        let searchVideosUseCase = SearchVideosUseCaseStub()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = searchVideosUseCase

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.searchVideos(for: "search")

        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testSearchVideosShouldReplaceResultsFromPreviousSearch() throws {
        let searchVideosUseCase = SearchVideosUseCaseStub()
        var environment = VideosListViewModel.Environment.noop
        environment.searchVideos = searchVideosUseCase

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
        searchVideosUseCase.loadedVideosSubject.send(videos1)
        searchVideosUseCase.loadedVideosSubject.send(completion: .finished)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            searchVideosUseCase.loadedVideosSubject = PassthroughSubject<[Video], Error>()
            viewModel.searchVideos(for: "search2")
            searchVideosUseCase.loadedVideosSubject.send(videos2)
            searchVideosUseCase.loadedVideosSubject.send(completion: .finished)
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

    func testVideosUpdateLikeStateWhenStateLikedVideoIDsChange() {
        let state: VideosListViewModel.State = .init(
            loading:.loaded,
            videos: [.mock(id: "id1"), .mock(id: "id2"), .mock(id: "id3")],
            likedVideoIDs: ["id2"]
        )
        let store = VideosListViewModel.StoreType(
            initialState: state,
            reducer: VideosListViewModel.reducer,
            environment: .dummy
        )

        let viewModel = VideosListViewModel(store: store)

        store.state.likedVideoIDs.removeAll()
        XCTAssertTrue(viewModel.videos.allSatisfy { $0.isLiked == false })

        store.state.likedVideoIDs.insert("id1")

        let likes = viewModel.videos.reduce(into: [:]) { $0[$1.id] = $1.isLiked }
        XCTAssertEqual(likes, ["id1": true, "id2": false, "id3": false])
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
        return .init(searchVideos: SearchVideosUseCaseStub())
    }

    static var noop: Self {
        return .dummy
    }
}

class SearchVideosUseCaseStub: SearchVideosUseCaseType {
    var loadedVideosSubject = PassthroughSubject<[Video], Error>()

    init(loadedVideosSubject: PassthroughSubject<[Video], Error> = .init()) {
        self.loadedVideosSubject = loadedVideosSubject
    }

    func videos(matching searchString: String) -> AnyPublisher<[Video], Error> {
        loadedVideosSubject.eraseToAnyPublisher()
    }
}

class SearchVideosUseCaseSpy: SearchVideosUseCaseStub {
    var didCallVideosMatching = false
    var givenSearchString: String?

    override func videos(matching searchString: String) -> AnyPublisher<[Video], Error> {
        didCallVideosMatching = true
        givenSearchString = searchString

        return super.videos(matching: searchString)
    }
}

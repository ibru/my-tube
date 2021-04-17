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

        XCTAssertEqual(viewModel.state.loading, .idle)
        XCTAssertEqual(viewModel.state.videos, [])
    }

    func testSearchForShouldPassSearchedStringToVideosRepository() throws {
        var actualSearchString = ""
        let environment = VideosListViewModel.Environment(searchVideos: SearchVideosClient(videosMatching: {
            actualSearchString = $0
            return .just([])
        }))

        let viewModel = VideosListViewModel(environment: environment)
        let expectedSearchString = "search"

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(1)

        viewModel.send(event: .onSearch(expectedSearchString))

        _ = try wait(for: recorder, timeout: 0.20)

        XCTAssertEqual(actualSearchString, expectedSearchString)
    }

    func testSearchForShouldTransitToLoadingAndLoadedLoadedStatesWithResultsFromVideosRepository() throws {
        let videos: [VideosListViewModel.VideoItem] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let searchString = "search"

        let viewModel = VideosListViewModel(reducer: VideosListViewModel.reducer, environment: .mock(with: videos))

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(2)

        viewModel.send(event: .onSearch(searchString))

        let states = try wait(for: recorder, timeout: 0.20)

        let expectedStates: [VideosListViewModel.State] = [
            .init(loading: .loading(searchString), videos: []),
            .init(loading: .loaded, videos: videos)
        ]

        XCTAssertEqual(states, expectedStates)
    }

    func testSearchforShouldChangeToLoadingAndNotDeleteVideosFromPreviousSearch() throws {
        let videos1: [VideosListViewModel.VideoItem] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let videos2: [VideosListViewModel.VideoItem] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        var videos = videos1

        let searchString1 = "search1"
        let searchString2 = "search2"

        let viewModel = VideosListViewModel(environment: .mock(with: videos))

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(4)

        viewModel.send(event: .onSearch(searchString1))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            videos = videos2

            viewModel.send(event: .onSearch(searchString2))
        }

        let states = try wait(for: recorder, timeout: 0.20)

        let expectedStates: [VideosListViewModel.State] = [
            .init(loading: .loading(searchString1), videos: []),
            .init(loading: .loaded, videos: videos1),
            .init(loading: .loading(searchString2), videos: videos1),
            .init(loading: .loaded, videos: videos2),
        ]

        XCTAssertEqual(states, expectedStates)
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

    static func mock(with videos: [VideosListViewModel.VideoItem]) -> Self {
        .init(
            searchVideos: SearchVideosClient(
                videosMatching: { _ in .just(videos) }
            )
        )
    }
}

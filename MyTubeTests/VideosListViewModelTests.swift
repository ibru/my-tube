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

    func testShouldStartEmpty() {
        let viewModel = VideosListViewModel()

        XCTAssertEqual(viewModel.state.loading, .idle)
        XCTAssertEqual(viewModel.state.videos, [])
    }

    func testSearchForShouldPassSearchedStringToVideosRepository() throws {
        var actualSearchString = ""
        let environment = VideosListEnvironment(searchVideos: SearchVideosClient(videosMatching: {
            actualSearchString = $0
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        }))

        let viewModel = VideosListViewModel(environment: environment)
        let expectedSearchString = "search"

        viewModel.send(event: .onSearch(expectedSearchString))

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(1)

        _ = try wait(for: recorder, timeout: 0.20)

        XCTAssertEqual(actualSearchString, expectedSearchString)
    }

    func testSearchForShouldTransitToLoadingAndLoadedLoadedStatesWithResultsFromVideosRepository() throws {
        let videos: [VideosListViewModel.VideoItem] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]

        let environment = VideosListEnvironment(searchVideos: SearchVideosClient(videosMatching: { _ in
            Just(videos)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }))
        let searchString = "search"

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.send(event: .onSearch(searchString))

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(2)


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

        let environment = VideosListEnvironment(searchVideos: SearchVideosClient(videosMatching: { _ in
            Just(videos)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }))

        let viewModel = VideosListViewModel(environment: environment)

        viewModel.send(event: .onSearch(searchString1))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            videos = videos2

            viewModel.send(event: .onSearch(searchString2))
        }

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(4)

        let states = try wait(for: recorder, timeout: 0.20)

        let expectedStates: [VideosListViewModel.State] = [
            .init(loading: .loading(searchString1), videos: []),
            .init(loading: .loaded, videos: videos1),
            .init(loading: .loading(searchString2), videos: videos1),
            .init(loading: .loaded, videos: videos2),
        ]

        XCTAssertEqual(states, expectedStates)
    }

    func testReduceShouldChangeStateToLoadingWhenIdleStateReceivesOnSearchEvent() {
        let searchString = "search"

        let state = VideosListViewModel.reduce(.init(loading:.idle, videos: []), .onSearch(searchString))

        XCTAssertEqual(state, .init(loading: .loading(searchString), videos: []))
    }
}

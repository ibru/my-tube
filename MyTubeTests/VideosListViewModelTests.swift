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

    func testShouldAskVideosRepositoryForListOfVideosWithSearchStringWhenOnSearchEventIsSent() throws {
        let repository = VideosRepositorySpy()
        let viewModel = VideosListViewModel(videosRepository: repository)
        let searchString = "search"

        viewModel.send(event: .onSearch(searchString))

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(1)


        let elements = try wait(for: recorder, timeout: 0.20)

        let states: [VideosListViewModel.State] = [
            .loading(searchString)
        ]

        XCTAssertEqual(elements, states)
        XCTAssertEqual(repository.givenSearchText, searchString)
    }

    func testStateShouldChangeToLoadingAndLoadedLoadedWithResultsFromVideosRepositoryWhenOnSearchEventIsSent() throws {
        let videos: [VideosListViewModel.VideoItem] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let repository = VideosRepositorySpy(videos: videos)
        let viewModel = VideosListViewModel(videosRepository: repository)
        let searchString = "search"

        viewModel.send(event: .onSearch(searchString))

        let recorder = viewModel.$state
            .dropFirst()
            .record()
            .next(2)


        let elements = try wait(for: recorder, timeout: 0.20)

        let states: [VideosListViewModel.State] = [
            .loading(searchString),
            .loaded(videos)
        ]

        XCTAssertEqual(elements, states)
    }

    func testReduceShouldChangeStateToLoadingWhenIdleStateReceivesOnSearchEvent() {
        let repository = VideosRepositorySpy()
        let viewModel = VideosListViewModel(videosRepository: repository)
        let searchString = "search"

        let state = VideosListViewModel.reduce(.idle, .onSearch(searchString))

        XCTAssertEqual(state, VideosListViewModel.State.loading(searchString))
    }
}

class VideosRepositorySpy: VideosRepository {
    var givenSearchText: String?
    var videos: [VideosListViewModel.VideoItem]

    init(videos: [VideosListViewModel.VideoItem] = []) {
        self.videos = videos
    }

    func videos(matching searchText: String) -> AnyPublisher<[VideosListViewModel.VideoItem], Error> {
        givenSearchText = searchText

        return Just(videos)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

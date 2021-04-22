//
//  VideosListViewModelToVideoDetailViewModelTests.swift
//  MyTubeIntegrationTests
//
//  Created by Jiri Urbasek on 4/21/21.
//

import XCTest
@testable import MyTube
import Combine

class VideosListViewModelToVideoDetailViewModelTests: XCTestCase {

    func testVideoInVideosListVMShouldUpdateWhenVideoDetailVMLikesIt() {
        let videos: [Video] = [
            .init(id: "id1", title: "Video 1", imageThumbnailUrl: nil),
            .init(id: "id2", title: "Video 2", imageThumbnailUrl: URL(string: "http://example.com"))
        ]
        let state: VideosListViewModel.State = .init(loading: .loaded, videos: videos, likedVideoIDs: [])

        let loadedVideosSubject = PassthroughSubject<[Video], Error>()
        let environment = VideosListViewModel.Environment(searchVideos: .init(videosMatching: { _ in
            loadedVideosSubject.eraseToAnyPublisher()
        }))

        let videosListVM = VideosListViewModel(initialState: state, environment: environment)
        let videoDetailVM = videosListVM.viewModel(forDetailOf: videosListVM.videos.first(where: { $0.id == "id2" })!)

        XCTAssertTrue(videosListVM.videos.allSatisfy { !$0.isLiked})
        XCTAssertFalse(videoDetailVM.isLiked)

        videoDetailVM.toggleLikeVideo()

        XCTAssertTrue(videoDetailVM.isLiked)
        XCTAssertFalse(videosListVM.videos.first(where: { $0.id == "id1" })!.isLiked)
        XCTAssertTrue(videosListVM.videos.first(where: { $0.id == "id2" })!.isLiked)
    }
}

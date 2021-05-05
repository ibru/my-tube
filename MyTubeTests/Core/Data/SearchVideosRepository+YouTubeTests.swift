//
//  SearchVideosRepository+YouTubeTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/3/21.
//

import XCTest
@testable import MyTube
import CombineExpectations

class SearchVideosRepositoryYouTubeTests: XCTestCase {
    func testShouldPassSearchStringToAPIFetcher() {
        let searchString = "search"
        var actualSearchString: String?

        let fetcher: SearchYoutubeVideosAPI = {
            actualSearchString = $0
            return .just([])
        }
        let repository = youTube(apiFetcher: fetcher)

        _ = repository(searchString)

        XCTAssertEqual(actualSearchString, searchString)
    }

    func testShouldReturnResultFromAPIFetcher() throws {
        let fetcher: SearchYoutubeVideosAPI = { _ in .just([
            .init(id: "id1", videoUrl: "watch.com/vid1".url, title: "video1", imageThumbnailUrl: "img.com/i".url),
            .init(id: "id2", videoUrl: "watch.com/vid2".url, title: "video2", imageThumbnailUrl: nil)
        ])}

        let repository = youTube(apiFetcher: fetcher)

        let videos = try repository("dummy")
            .record()
            .single
            .get()

        XCTAssertEqual(videos.count, 2)
        XCTAssertEqual(videos.first?.id, "id1")
        XCTAssertEqual(videos.first?.title, "video1")
        XCTAssertEqual(videos.first?.imageThumbnailUrl, "img.com/i".url)
    }

}

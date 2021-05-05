//
//  VideosListViewModelMocks.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/4/21.
//

import Foundation
@testable import MyTube

// TODO: maybe we should make this be part of MyTube target only when DEBUG mode is on?
extension VideosListViewModel.Environment {
    static var noop: Self {
        .init(
            searchVideos: { _ in .empty() },
            loadSavedVideos: { .empty() }
        )
    }

    static func mock(savedVideos: [Video] = [], searchedVideos: [Video] = []) -> Self {
        .init(
            searchVideos: { _ in .just(searchedVideos) },
            loadSavedVideos: { .just(savedVideos) }
        )
    }
}

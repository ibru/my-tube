//
//  Endpoint+searchVideos.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/30/21.
//

import Foundation

public extension Endpoint where Response == [YoutubeVideo] {
    static func searchVideos(searchText: String) -> Self {
        var endpoint = Endpoint(
            path: "/search",
            queryItems: [
                .init(name: "q", value: "\(searchText)"),
                .init(name: "part", value: "snippet"),
                .init(name: "maxResults", value: "25")
            ]
        )

        endpoint.mapResponse = { data, decoder in
            var videos: [YoutubeVideo] = []

            let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

            if let videosArr = json["items"] as? [[String: Any]] {
                for videoJson in videosArr {
                    guard let idJson = videoJson["id"] as? [String: Any], let id = idJson["videoId"] as? String,
                        let snipetJson = videoJson["snippet"] as? [String: Any], let title = snipetJson["title"] as? String,
                        let thumbnailJson = snipetJson["thumbnails"] as? [String: [String: Any]],
                        let thumbnailUrl = thumbnailJson["high"]?["url"] as? String else {
                            continue
                    }
                    let video = YoutubeVideo(id: id, videoUrl: URL(string: "https://www.youtube.com/watch?v=\(id)")!, title: title, imageThumbnailUrl: URL(string: thumbnailUrl)!)
                    videos.append(video)
                }
            }
            return videos
        }
        return endpoint
    }
}

public struct YoutubeVideo: Codable {
    public let id: String
    public let videoUrl: URL
    public let title: String
    public let imageThumbnailUrl: URL?
}

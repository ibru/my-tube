//
//  YoutubeVideosRepository.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/29/21.
//

import Foundation
import Combine

final class YoutubeVideosRepository {
    func videos(for searchString: String) -> AnyPublisher<[YoutubeVideo], URLError> {
        let urlString = "https://www.googleapis.com/youtube/v3/search/?part=snippet&maxResults=25&q=\(searchString)&key=<put your YouTube Data API Key here>"
        let url = URL(string: urlString)!

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> [YoutubeVideo] in
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
            .eraseToAnyPublisher()
    }
}

struct YoutubeVideo {
    let id: String
    let videoUrl: URL
    let title: String
    let imageThumbnailUrl: URL?
}

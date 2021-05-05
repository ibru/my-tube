//
//  Endpoint+SearchVideosTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/3/21.
//

import XCTest
@testable import MyTube

class EndpointSearchVideosTests: XCTestCase {
    func testCorrectURLParams() throws {
        let endpoint = Endpoint.searchVideos(searchText: "fun")
        let urlString = try endpoint.makeRequest(.init(scheme: "http", host: "a.com", pathPrefix: "", apiKey: "mykey"))
            .url?.absoluteString

        XCTAssertEqual(urlString, "http://a.com/search?q=fun&part=snippet&maxResults=25&key=mykey")
    }

    func testParseSuccessResponse() throws {
        let endpoint = Endpoint.searchVideos(searchText: "fun")

        let videos = try endpoint.mapResponse(successResponse, .init())

        XCTAssertEqual(videos.count, 2)
        XCTAssertEqual(videos.first?.id, "F5MGoX1Atnc")
        XCTAssertEqual(videos.first?.videoUrl, "https://www.youtube.com/watch?v=F5MGoX1Atnc".url)
        XCTAssertEqual(videos.first?.title, "Peppa Pig Official Channel | Peppa Pig at the Hospital | Peppa Pig Boo Boo Moments")
        XCTAssertEqual(videos.first?.imageThumbnailUrl, "https://i.ytimg.com/vi/F5MGoX1Atnc/hqdefault.jpg".url)
    }
}

private let successResponse = """
{
  "kind": "youtube#searchListResponse",
  "etag": "YbSP5Qmx42qRQrY4iPEOxBa3NN0",
  "nextPageToken": "CAoQAA",
  "regionCode": "CZ",
  "pageInfo": {
    "totalResults": 1000000,
    "resultsPerPage": 10
  },
  "items": [
    {
      "kind": "youtube#searchResult",
      "etag": "qiAvBpo7N0n_dKfk7SxHBdV2TbM",
      "id": {
        "kind": "youtube#video",
        "videoId": "F5MGoX1Atnc"
      },
      "snippet": {
        "publishedAt": "2021-04-29T05:00:09Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig Official Channel | Peppa Pig at the Hospital | Peppa Pig Boo Boo Moments",
        "description": "Peppa Pig Official Channel | Peppa Pig at the Hospital | Peppa Pig Boo Boo Moments | Peppa Pig at the Hospital Episode | Peppa Pig English Episodes | Peppa ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/F5MGoX1Atnc/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/F5MGoX1Atnc/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/F5MGoX1Atnc/hqdefault.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "none",
        "publishTime": "2021-04-29T05:00:09Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "Nd5eqg4dMNLZBDeNJ3O_NLO98Zg",
      "id": {
        "kind": "youtube#video",
        "videoId": "a4Z78O03lzg"
      },
      "snippet": {
        "publishedAt": "2021-04-29T05:00:00Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig Official Channel | Is it Baby Alexander or Baby Peppa Pig?",
        "description": "Peppa Pig Official Channel | Is it Baby Alexander or Baby Peppa Pig? | Peppa Pig the Olden Days Episode | Peppa Pig English Episodes | Peppa Pig Full ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/a4Z78O03lzg/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/a4Z78O03lzg/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/a4Z78O03lzg/hqdefault.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "none",
        "publishTime": "2021-04-29T05:00:00Z"
      }
    }
  ]
}
""".data(using: .utf8)!

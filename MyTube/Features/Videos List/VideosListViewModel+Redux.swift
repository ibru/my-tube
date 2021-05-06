//
//  VideosListViewModel+Redux.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/19/21.
//

import Foundation
import Combine
import CombineSchedulers

extension VideosListViewModel {
    typealias StoreType = Store<State, Action>

    enum Error: Swift.Error, Equatable {
        case couldNotSearchVideos
        case couldNotLocallyLoadVideos
    }

    struct State: Equatable {
        enum SearchingState: Equatable {
            case idle
            case searching(String)
            case finished
            case error(Error)
        }

        enum LoadingState: Equatable {
            case idle
            case loading
            case loaded
            case error(Error)
        }

        var searching: SearchingState
        var localVideosLoading: LoadingState
        var videos: [Video]

        // TODO: better approach would be to save whole Videos instead of just set of IDs. I keep it like this
        // for now for sake of exploration and learning
        var likedVideoIDs: Set<String>

        init(locallyLoading: LoadingState = .idle, searching: SearchingState = .idle, videos: [Video] = [], likedVideoIDs: Set<String> = []) {
            self.localVideosLoading = locallyLoading
            self.searching = searching
            self.videos = videos
            self.likedVideoIDs = likedVideoIDs
        }

        func isLiked(videoId: String) -> Bool {
            likedVideoIDs.contains(videoId)
        }
    }

    enum Action {
        case onAppear
        case onSearch(String)
        case onSearchedVideos([Video])
        case onSearchedVideosError(Error)
        case onLocallyLoadedVideos([Video])
        case onLocallyLoadedVideosError(Error)
    }

    struct Environment {
        var mainQueue: AnySchedulerOf<DispatchQueue>
        var searchVideos: SearchVideosUseCase
        var loadSavedVideos: LoadSavedVideosUseCase
    }
}

extension VideosListViewModel.Environment {
    static var live: Self {
        .init(
            mainQueue: .main,
            searchVideos: MyTube.live(
                repository: youTube(
                    apiFetcher: {
                        Endpoint.searchVideos(searchText: $0)
                            .send(environment: .searchMock)
                    }
                )
            ), loadSavedVideos: grdb(
                repository: {
                    let db = GRDBAppDatabase.shared
                    return .live(dbReader: db.dbReader, dbWriter: db.dbWriter)
                }()
            )
        )
    }

#if DEBUG
    static var noop: Self {
        .init(
            mainQueue: .immediate,
            searchVideos: { _ in .empty() },
            loadSavedVideos: { .empty() }
        )
    }
#endif
}

extension VideosListViewModel {
    typealias ReducerType = Reducer<State, Action, Environment>

    static var reducer: ReducerType = {
        .init { (state, action, environment) -> Effect<Action, Never> in
            switch action {
            case .onAppear:
                state.localVideosLoading = .loading
                return Effects.loadSavedVideos(using: environment.loadSavedVideos)

            case .onSearch(let searchString):
                state.searching = .searching(searchString)
                return Effects.searchStringPublisher(
                    searchText: searchString,
                    using: environment.searchVideos,
                    scheduler: environment.mainQueue
                )

            case .onSearchedVideos(let videos):
                state.videos = videos
                state.searching = .finished
                return .none

            case .onSearchedVideosError(let error):
                state.searching = .error(error)
                return .none

            case .onLocallyLoadedVideos(let videos):
                state.videos = videos
                state.likedVideoIDs = Set(videos.map(\.id))
                state.localVideosLoading = .loaded
                return .none

            case .onLocallyLoadedVideosError(let error):
                state.localVideosLoading = .error(error)
                return.none
            }
        }
    }()
}

extension VideosListViewModel {
    struct Effects {
        static func searchStringPublisher(searchText: String, using useCase: SearchVideosUseCase, scheduler: AnySchedulerOf<DispatchQueue>) -> Effect<Action, Never> {
            useCase(searchText)
                .receive(on: scheduler)
                .map(Action.onSearchedVideos)
                .replaceError(with: .onSearchedVideosError(.couldNotSearchVideos))
                .eraseToEffect()
        }

        static func loadSavedVideos(using useCase: LoadSavedVideosUseCase) -> Effect<Action, Never> {
            useCase()
                .map(Action.onLocallyLoadedVideos)
                .replaceError(with: .onLocallyLoadedVideosError(.couldNotLocallyLoadVideos))
                .eraseToEffect()
        }
    }
}

extension VideosListViewModel.StoreType {
    static func create(
        initialState: VideosListViewModel.State = .init(),
        reducer: Reducer<VideosListViewModel.State, VideosListViewModel.Action, VideosListViewModel.Environment> = VideosListViewModel.reducer,
        environment: VideosListViewModel.Environment = .live
    ) -> Self {
        .init(initialState: initialState, reducer: reducer, environment: environment)
    }
}

extension Networking.Environment {
    static var searchMock: Self {
        .init(
            responseDataProvider: { _ in
                Just(searchJSON)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }, jsonDecoder: .init())
    }
}

let searchJSON = """
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
    },
    {
      "kind": "youtube#searchResult",
      "etag": "mfyvWp2SCZ0bb2NQXq7ga6UY95A",
      "id": {
        "kind": "youtube#video",
        "videoId": "RellvTAkhqQ"
      },
      "snippet": {
        "publishedAt": "2020-09-09T07:51:08Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig Official Channel 💛 LIVE! 💛 Peppa Pig Toy Play",
        "description": "Subscribe for more videos: http://bit.ly/PeppaPigYT #Peppa #PeppaPig #PeppaPigEnglish ❤️ Watch the latest uploads here!",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/RellvTAkhqQ/default_live.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/RellvTAkhqQ/mqdefault_live.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/RellvTAkhqQ/hqdefault_live.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "live",
        "publishTime": "2020-09-09T07:51:08Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "LF98ZGDxxkP36AVaPGvb4doOKUI",
      "id": {
        "kind": "youtube#video",
        "videoId": "u1ELLHUvHp4"
      },
      "snippet": {
        "publishedAt": "2020-09-09T12:05:17Z",
        "channelId": "UCF9IpcBgYvMS3GKkM_xwiqA",
        "title": "🔴 Peppa Pig Hindi - Live - Hindi Cartoons - हिंदी Kahaniya",
        "description": "Peppa Pig Hindi - Live Stream -हिंदी Kahaniya - Hindi Cartoons for Kids ☆ Subscribe: http://bit.ly/PeppaHindi ☆ Aap dekh rahe hai Peppa Pig ka official ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/u1ELLHUvHp4/default_live.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/u1ELLHUvHp4/mqdefault_live.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/u1ELLHUvHp4/hqdefault_live.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig Hindi",
        "liveBroadcastContent": "live",
        "publishTime": "2020-09-09T12:05:17Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "1jVY7UwOnQJKoOfaJAuJ-7r7iJw",
      "id": {
        "kind": "youtube#video",
        "videoId": "j-PRC-qRoKE"
      },
      "snippet": {
        "publishedAt": "2021-04-27T05:00:30Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig Official Channel | Peppa Pig&#39;s Goldie the Fish Becomes Gigantic!",
        "description": "Peppa Pig Official Channel | Peppa Pig's Goldie the Fish Becomes Gigantic! | Peppa Pig English Episodes | Peppa Pig Full Episodes ✨✨✨✨✨✨✨✨✨✨✨ About ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/j-PRC-qRoKE/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/j-PRC-qRoKE/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/j-PRC-qRoKE/hqdefault.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "none",
        "publishTime": "2021-04-27T05:00:30Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "2E15T4k_VwWe04-2sjAP3CkWDyE",
      "id": {
        "kind": "youtube#video",
        "videoId": "SAxjTdW9oo8"
      },
      "snippet": {
        "publishedAt": "2021-04-24T05:00:15Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig Official Channel | Peppa Pig Boo Boo Moments and The Ambulance",
        "description": "Peppa Pig Official Channel | Peppa Pig Boo Boo Moments and The Ambulance | Peppa Pig English Episodes | Peppa Pig Full Episodes ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/SAxjTdW9oo8/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/SAxjTdW9oo8/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/SAxjTdW9oo8/hqdefault.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "none",
        "publishTime": "2021-04-24T05:00:15Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "O_KiYco8JNa3sUvNBVyNELrErzA",
      "id": {
        "kind": "youtube#video",
        "videoId": "hH5R3b0qm98"
      },
      "snippet": {
        "publishedAt": "2021-04-29T06:00:20Z",
        "channelId": "UCzkA5UTtr_vNYqMSB3DisVA",
        "title": "Peppa Pig Official Channel | Hospital | Peppa Pig Season 4",
        "description": "| Peppa Pig English Episodes | Peppa Pig Full Episodes ✨✨✨✨✨✨✨✨✨✨✨ About Peppa Pig official channel: Welcome to the Official Peppa Pig channel and the ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/hH5R3b0qm98/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/hH5R3b0qm98/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/hH5R3b0qm98/hqdefault.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig Asia",
        "liveBroadcastContent": "none",
        "publishTime": "2021-04-29T06:00:20Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "1nc-yk7c-Ini1p086Aa0KwN3BdY",
      "id": {
        "kind": "youtube#video",
        "videoId": "UTpSdT3B3MI"
      },
      "snippet": {
        "publishedAt": "2021-04-28T08:00:06Z",
        "channelId": "UCu52CCCjTx-U1BgDO4ZOSpw",
        "title": "Peppa Pig Official Channel | The Olden Days",
        "description": "| Peppa Pig English Episodes | Peppa Pig Full Episodes ✨✨✨✨✨✨✨✨✨✨✨ About Peppa Pig official channel: Welcome to the Official Peppa Pig channel and the ...",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/UTpSdT3B3MI/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/UTpSdT3B3MI/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/UTpSdT3B3MI/hqdefault.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig Toy Videos",
        "liveBroadcastContent": "none",
        "publishTime": "2021-04-28T08:00:06Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "SI3yasz5uohU40IDn0HlTooVrj0",
      "id": {
        "kind": "youtube#video",
        "videoId": "jvXesDzDYJA"
      },
      "snippet": {
        "publishedAt": "2020-11-16T14:09:35Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig Official Channel 💚 Peppa Pig Episodes Live 24/7",
        "description": "Subscribe for more videos: http://bit.ly/PeppaPigYT #Peppa #PeppaPig #PeppaPigEnglish ❤️ Watch the latest uploads here!",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/jvXesDzDYJA/default_live.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/jvXesDzDYJA/mqdefault_live.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/jvXesDzDYJA/hqdefault_live.jpg",
            "width": 480,
            "height": 360
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "live",
        "publishTime": "2020-11-16T14:09:35Z"
      }
    },
    {
      "kind": "youtube#searchResult",
      "etag": "9NQUeBca21-Yet6YR3kZ2AkUHIQ",
      "id": {
        "kind": "youtube#channel",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg"
      },
      "snippet": {
        "publishedAt": "2013-10-09T13:07:35Z",
        "channelId": "UCAOtE1V7Ots4DjM8JLlrYgg",
        "title": "Peppa Pig - Official Channel",
        "description": "Peppa lives with her mummy and daddy and her little brother, George. Her adventures are fun, sometimes involve a few tears, but always end happily. Welcome ...",
        "thumbnails": {
          "default": {
            "url": "https://yt3.ggpht.com/ytc/AAUvwnh9rdx1-eqT1DmY2nTORBYgGSIyDahAe9D06-k1dg=s88-c-k-c0xffffffff-no-rj-mo"
          },
          "medium": {
            "url": "https://yt3.ggpht.com/ytc/AAUvwnh9rdx1-eqT1DmY2nTORBYgGSIyDahAe9D06-k1dg=s240-c-k-c0xffffffff-no-rj-mo"
          },
          "high": {
            "url": "https://yt3.ggpht.com/ytc/AAUvwnh9rdx1-eqT1DmY2nTORBYgGSIyDahAe9D06-k1dg=s800-c-k-c0xffffffff-no-rj-mo"
          }
        },
        "channelTitle": "Peppa Pig - Official Channel",
        "liveBroadcastContent": "live",
        "publishTime": "2013-10-09T13:07:35Z"
      }
    }
  ]
}
""".data(using: .utf8)!

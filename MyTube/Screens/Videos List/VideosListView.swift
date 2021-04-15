//
//  VideosListView.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/24/21.
//

import SwiftUI

struct VideosListView: View {
    @ObservedObject var viewModel: VideosListViewModel
    @State var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    SearchBar(text: $searchText)
                        .padding(.leading, 10)

                    Button(action: {
                        viewModel.send(event: .onSearch(searchText))
                    }, label: {
                        Text("Search")
                    })
                    .padding(.horizontal, 15)
                }
                
                content
            }
            .navigationTitle("Search videos")
        }
        .onAppear {
            viewModel.send(event: .onAppear)
        }
    }

    var content: some View {
        List(viewModel.state.videos) { item in
            NavigationLink(
                destination: VideoDetailView(video: item),
                label: {
                    HStack {
                        ZStack(alignment: .bottomTrailing) {
                            if let url = item.imageThumbnailUrl {
                                AsyncImage(
                                    url: url,
                                    placeholder: { Text("Loading ...") },
                                    image: {
                                        Image(uiImage: $0)
                                            .resizable()
                                    }
                                )
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 100)
                            } else {
                                Image("peppa_pig_video_thumbnail")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 100)
                                    .redacted(reason: .placeholder)
                            }

                            Text("1:04:43 ")
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(1)
                                .background(Color.white)
                                .padding(1)
                        }

                        VideoInfoView(video: item)
                            .padding(5)
                    }
                })
        }
        .listStyle(PlainListStyle())
    }
}

import Combine

struct VideosListView_Previews: PreviewProvider {
    static var previews: some View {
        VideosListView(
            viewModel: VideosListViewModel(
                initialState: .init(loading: .loaded, videos: items),
                environment: VideosListEnvironment(searchVideos: SearchVideosClient(videosMatching: { _ in
                    Just(items)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }))
            )
        )
    }

    static var items: [VideosListViewModel.VideoItem] = [
        .init(id: "123", title: "Video title", imageThumbnailUrl: nil),
        .init(id: "456", title: "Video 2 title", imageThumbnailUrl: nil),
        .init(id: "6789", title: "Video 3 title", imageThumbnailUrl: nil)
    ]

    static let error: Error = NSError(domain: "Preview", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is preview error."])
}

extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}


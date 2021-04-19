//
//  VideoDetailView.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/25/21.
//

import SwiftUI

struct VideoDetailView: View {
    //var video: VideosListViewModel.VideoItem
    @ObservedObject var viewModel: VideoDetailViewModel

    var body: some View {
        VStack {
            ZStack {
                ZStack(alignment: .bottomTrailing) {
                    if let url = viewModel.video.imageThumbnailUrl {
                        AsyncImage(
                            url: url,
                            placeholder: { Text("Loading ...") },
                            image: {
                                Image(uiImage: $0)
                                    .resizable()
                            }
                        )
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        .clipped()
                    } else {
                        Text("No image available...")
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .background(Rectangle().stroke())
                    }

                    Text("1:04:43")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Color.white)
                        .padding(2)

                }

                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    Image(systemName: "play.fill")
                        .resizable()
                        .foregroundColor(.primary)
                        .shadow(radius: 10)
                        .frame(width: 60, height: 60)
                })
            }

            VideoInfoView(video: .init(video: viewModel.video), isLiked: viewModel.isLiked)
                .padding()


            Button(action: {
                viewModel.toggleLikeVideo()
            }, label: {
                if viewModel.isLiked {
                    Label("Remove from Favorites", systemImage: "star.fill")
                } else {
                    Label("Add to Favorites", systemImage: "star")
                }
            })
            .padding(6)

            Button(action: {}, label: {
                Label("Watch on YouTube", systemImage: "video")
            })
            .padding(6)
        }
    }
}

import Combine

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoDetailView(
                viewModel: VideoDetailViewModel(
                    store: .init(
                        initialState: .init(
                            video: .init(id: "123", title: "VIdeo title", imageThumbnailUrl: nil),
                            isLiked: true,
                            likeVideoError: nil
                        ),
                        reducer: .empty,
                        environment: VideoDetailViewModel.Environment(
                            likeVideo: .init(
                                likeWithID: { _ in
                                    Just(true)
                                        .setFailureType(to: Error.self)
                                        .eraseToAnyPublisher()
                                }, dislikeWithID: { _ in
                                    Just(true)
                                        .setFailureType(to: Error.self)
                                        .eraseToAnyPublisher()
                                }
                            )
                        )
                    )
                )
            )
        }
    }
}

struct VideoInfoView: View {
    let video: VideoItem
    let isLiked: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(video.title + (isLiked ? " ✰" : ""))
                .font(.headline)
                .lineLimit(2)
            Text("225k views")
                .font(.subheadline)

            HStack {
                Image("peppa_ping_channel_avatar")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25)
                Text("Peppa Pig - Official channel")
                    .font(.caption)
            }
        }
    }
}
extension VideoInfoView {
    struct VideoItem: Equatable, Identifiable {
        let id: String
        let title: String
        let imageThumbnailUrl: URL?

        init(video: VideosListViewModel.VideoItem) {
            id = video.id
            title = video.title
            imageThumbnailUrl = video.imageThumbnailUrl
        }

        init(video: VideoDetailViewModel.VideoItem) {
            id = video.id
            title = video.title
            imageThumbnailUrl = video.imageThumbnailUrl
        }
    }
}

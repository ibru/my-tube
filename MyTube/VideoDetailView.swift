//
//  VideoDetailView.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/25/21.
//

import SwiftUI

struct VideoDetailView: View {
    var video: VideosListViewModel.VideoItem

    var body: some View {
        VStack {
            ZStack {
                ZStack(alignment: .bottomTrailing) {
                    Image("peppa_pig_video_thumbnail")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        .clipped()

                    Text("1:04:43")
                        .font(.caption)
                        .foregroundColor(.black)
                        .frame(width: .infinity, height: .infinity, alignment: .bottomTrailing)

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

            VideoInfoView(video: video)
                .padding()


            Button(action: {}, label: {
                Label("Add to Favorites", systemImage: "star")
            })
            .padding(6)

            Button(action: {}, label: {
                Label("Watch on YouTube", systemImage: "video")
            })
            .padding(6)
        }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoDetailView(video: .init(id: "123", title: "VIdeo title", imageThumbnailUrl: nil))
        }
    }
}

struct VideoInfoView: View {
    var video: VideosListViewModel.VideoItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(video.title)
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

//
//  VideosListView.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/24/21.
//

import SwiftUI

struct VideosListView: View {
    var body: some View {
        List {
            ForEach(1..<5) { _ in
                HStack {
                    Image("peppa_pig_video_thumbnail")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 60)

                    VStack(alignment: .leading) {
                        Text("Peppa Pig Official Channel 💚 Peppa Pig Episodes Live 24/7")
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
                    .padding(5)
                }
            }
        }
    }
}

struct VideosListView_Previews: PreviewProvider {
    static var previews: some View {
        VideosListView()
            .previewDevice("iPad Pro")
    }
}

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
                    ZStack(alignment: .bottomTrailing) {
                        Image("peppa_pig_video_thumbnail")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 100)

                        Text("1:04:43 ")
                            .font(.caption)
                            .foregroundColor(.black)
                            .frame(width: .infinity, height: .infinity, alignment: .bottomTrailing)
                            .background(Color.white)
                    }

                    VideoInfoView()
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

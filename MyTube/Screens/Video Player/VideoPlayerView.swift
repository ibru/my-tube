//
//  VideoPlayerView.swift
//  MyTube
//
//  Created by Jiri Urbasek on 2/4/21.
//

import SwiftUI

struct VideoPlayerView: View {
    var body: some View {
        Image("peppa_pig_video_thumbnail")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(
                HStack {
                    VStack {
                        lockButton()
                        Spacer()
                        lockButton()
                    }
                    .padding(8)
                },
                alignment: .leading
            )
    }
}

extension VideoPlayerView {
    @ViewBuilder func lockButton() -> some View {
        Image(systemName: "lock")
            .resizable()
            .foregroundColor(.white)
            .aspectRatio(contentMode: .fit)
            .padding(4)
            .frame(width: 25)
            .padding(10)
            .background(
                Color.black
                    .opacity(0.4)
                    .clipShape(Circle())
            )
            .background(
                Circle()
                    .strokeBorder(Color.black, lineWidth: 1)
                    .opacity(0.6)
            )
            .opacity(0.5)
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView()
            .previewLayout(.fixed(width: 2082 / 3.0, height: 1170 / 3.0))
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.verticalSizeClass, .compact)
    }
}

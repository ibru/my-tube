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
        switch viewModel.state {
        case .idle:
            return Color.clear
                .eraseToAnyView()
        case .loading:
            return List {
                Text("Loading...")
            }
            .eraseToAnyView()

        case .loaded(let items):
            return list(of: items)
                .eraseToAnyView()

        case .error(let error):
            return Text(error.localizedDescription)
                .eraseToAnyView()
        }
    }

    fileprivate func list(of items: [VideosListViewModel.VideoItem]) -> some View {
        List(items) { item in
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
                            .padding(1)
                            .background(Color.white)
                            .padding(1)
                    }

                    VideoInfoView()
                        .padding(5)
                }
            }
    }
}

struct VideosListView_Previews: PreviewProvider {
    static var previews: some View {
        VideosListView(
            viewModel: VideosListViewModel(
                initialState: .loaded(items),
                videosRepository: MockVideosRepository()
            )
        )
    }

    static var items: [VideosListViewModel.VideoItem] = [
        .init(id: "123", title: "VIdeo title", imageThumbnailUrl: nil),
        .init(id: "456", title: "VIdeo 2 title", imageThumbnailUrl: nil),
        .init(id: "6789", title: "VIdeo 3 title", imageThumbnailUrl: nil)
    ]

    static let error: Error = NSError(domain: "Preview", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is preview error."])
}

extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}


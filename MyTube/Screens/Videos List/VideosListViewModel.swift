//
//  VideosListViewModel.swift
//  MyTube
//
//  Created by Jiri Urbasek on 1/26/21.
//

import Foundation
import Combine


protocol VideosRepository {
    func videos(matching searchText: String) -> AnyPublisher<[VideosListViewModel.VideoItem], Error>
}

final class VideosListViewModel: ObservableObject {
    @Published var state: State

    private var bag = Set<AnyCancellable>()

    private let input = PassthroughSubject<Event, Never>()


    init(initialState: State = .idle, videosRepository: VideosRepository) {
        state = initialState

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.searchString(using: videosRepository),
                Self.debug(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }

    deinit {
        bag.removeAll()
    }

    func send(event: Event) {
        input.send(event)
    }
}

extension VideosListViewModel {
    enum Error: Swift.Error, Equatable {
        case unknown
    }
    enum State: Equatable {
        case idle
        case loading(String)
        case loaded([VideoItem])
        case error(Error)
    }

    enum Event {
        case onAppear
        case onSearch(String)
        case onLoadVideos([VideoItem])
        case onLoadVideosError(Error)
    }
}

extension VideosListViewModel {
    struct VideoItem: Equatable, Identifiable {
        let id: String
        let title: String
        let imageThumbnailUrl: URL?
    }
}


extension VideosListViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .onSearch(let searchText):
                return .loading(searchText)
            default:
                return state
            }

        case .loading:
            switch event {
            case .onLoadVideos(let videos):     return .loaded(videos)
            case .onLoadVideosError(let error): return .error(error)
            default:                            return state
            }

        case .loaded:
            switch event {
            case .onSearch(let searchText):
                return .loading(searchText)
            default:
                return state
            }

        case .error:
            switch event {
            case .onSearch(let searchText):
                return .loading(searchText)
            default:
                return state
            }
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }

    static func debug() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            print("State changed: \(state)")
            return Empty().eraseToAnyPublisher()
        }
    }

    static func searchString(using repository: VideosRepository) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading(let searchText) = state else { return Empty().eraseToAnyPublisher() }

            return repository.videos(matching: searchText)
                .map(Event.onLoadVideos)
                .replaceError(with: .onLoadVideosError(.unknown))
                .eraseToAnyPublisher()
        }
    }
}


// TODO: Move to separate file
final class MockVideosRepository: VideosRepository {
    func videos(matching searchText: String) -> AnyPublisher<[VideosListViewModel.VideoItem], Error> {
        return Just([
            .init(id: "123", title: "VIdeo title", imageThumbnailUrl: nil),
            .init(id: "456", title: "VIdeo 2 title", imageThumbnailUrl: nil),
            .init(id: "6789", title: "VIdeo 3 title", imageThumbnailUrl: nil)
        ])
        .setFailureType(to: Error.self)
        .delay(for: .seconds(2), scheduler: RunLoop.main)
        .eraseToAnyPublisher()
    }
}

//
//  Helpers.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 4/18/21.
//

import Foundation
import Combine

extension AnyPublisher {
    static func just<Output, Failure>(_ value: Output) -> AnyPublisher<Output, Failure> {
        Just(value)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }

    static func empty<Output, Failure>(
        completeImmediately: Bool = true
    ) -> AnyPublisher<Output, Failure> {
        Empty(completeImmediately: true, outputType: Output.self, failureType: Failure.self)
            .eraseToAnyPublisher()
    }

    static func fail<Output, Failure>(_ error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error).eraseToAnyPublisher()
    }
}

struct MockError: Error, Equatable {
    var message: String
}

extension String {
    var url: URL { URL(string: self)! }
    var request: URLRequest { .init(url: url) }
}

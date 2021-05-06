//
//  Publisher+ext.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/6/21.
//

import Foundation
import Combine

extension Publisher {
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

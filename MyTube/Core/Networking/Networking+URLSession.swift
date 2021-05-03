//
//  Networking+URLSession.swift
//  MyTube
//
//  Created by Jiri Urbasek on 5/3/21.
//

import Foundation
import Combine

public extension URLSession {
    var provider: Networking.ResponseDataProvider {
        {
            self.dataTaskPublisher(for: $0)
                .tryMap { element -> Data in
                    guard let httpResponse = element.response as? HTTPURLResponse,
                        200...299 ~= httpResponse.statusCode else {
                        throw URLError(.badServerResponse)
                    }
                    return element.data
                }
                .eraseToAnyPublisher()
        }
    }
}

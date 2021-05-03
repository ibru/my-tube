//
//  Networking.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/30/21.
//

import Foundation
import Combine

public enum Networking {
    public enum Error: Swift.Error {
        case buildRequest(Swift.Error)
        case getResponse(Swift.Error)
        case decodeResponse(Swift.Error)
    }

    public typealias RequestProvider = () throws -> URLRequest
    public typealias ResponseDataProvider = (URLRequest) -> AnyPublisher<Data, Swift.Error>
    public typealias ResponseDataMapper<T: Decodable> = (Data) throws -> T
}

extension Networking {
    static func send<T>(
        _ request: @escaping RequestProvider,
        using dataProvider: @escaping ResponseDataProvider,
        mappingWith mapper: @escaping ResponseDataMapper<T>
    ) -> AnyPublisher<T, Error> {
        do {
            let r = try request()

            return dataProvider(r)
                .mapError(Error.getResponse)
                .tryMap(mapper)
                .mapError { error in
                    (error as? Error).map { return $0 } ?? .decodeResponse(error)
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: Networking.Error.buildRequest(error))
                .eraseToAnyPublisher()
        }
    }
}

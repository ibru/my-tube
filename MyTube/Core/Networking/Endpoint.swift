//
//  Endpoint.swift
//  MyTube
//
//  Created by Jiri Urbasek on 4/30/21.
//

import Foundation
import Combine

public struct Endpoint<Response: Decodable> {
    public let path: String
    public let queryItems: [URLQueryItem]

    public var makeRequest: (Networking.ServerConfiguration) throws -> URLRequest
    public var mapResponse: (Data, JSONDecoder) throws -> Response

    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    public typealias JSONString = String

    public init(
        method: Method = .get,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: JSONString? = nil
    ) {
        self.path = path
        self.queryItems = queryItems

        makeRequest = {
            var components = URLComponents()
            components.scheme = $0.scheme
            components.host = $0.host
            components.path = $0.pathPrefix + path

            var items = queryItems
            items.append(.init(name: "key", value: $0.apiKey))
            components.queryItems = items

            guard let url = components.url else { throw URLError(.badURL) }

            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpBody = body.map { $0.data(using: .utf8) } ?? nil

            return request
        }

        mapResponse = { try $1.decode(Response.self, from: $0) }
    }
}

public extension Networking {
    struct Environment {
        public let responseDataProvider: ResponseDataProvider
        public let jsonDecoder: JSONDecoder

        public static var live: Self {
            .init(responseDataProvider: URLSession.shared.provider, jsonDecoder: .init())
        }
    }

    struct ServerConfiguration: Equatable {
        public static var current: ServerConfiguration = .production

        public let scheme: String
        public let host: String
        public let pathPrefix: String
        public let apiKey: String

        public static var production: Self {
            .init(
                scheme: "https",
                host: "www.googleapis.com",
                pathPrefix: "/youtube/v3",
                apiKey: "put your api key here"
            )
        }
    }
}

public extension Endpoint {
    func send(
        using serverConfiguration: Networking.ServerConfiguration = .current,
        environment: Networking.Environment = .live
    ) -> AnyPublisher<Response, Networking.Error> {
        return Networking.send(
            { try makeRequest(serverConfiguration) },
            using: environment.responseDataProvider,
            mappingWith: { try mapResponse($0, environment.jsonDecoder) }
        )
    }
}

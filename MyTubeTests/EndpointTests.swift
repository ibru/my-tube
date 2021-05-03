//
//  EndpointTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/3/21.
//

import XCTest
@testable import MyTube
import Combine
import CombineExpectations

class EndpointTests: XCTestCase {
    func testSendShouldCreateRequestUsingGivenServerConfiguration() {
        let config = Networking.ServerConfiguration(scheme: "a", host: "b", pathPrefix: "c", apiKey: "d")
        var actualConfig: Networking.ServerConfiguration?

        var endpoint = Endpoint<String>(path: "/profile")
        endpoint.makeRequest = {
            actualConfig = $0
            return "www.exmaple.com".request
        }

        _ = endpoint.send(using: config, environment: .dummy)

        XCTAssertEqual(actualConfig, config)
    }

    func testSendShouldProvideResponseDataUsingEnvironmentResponseDataProvider() {
        var dataProviderUsed = false
        let environment = Networking.Environment(
            responseDataProvider: { _ in
                dataProviderUsed = true
                return .just(Data())
            },
            jsonDecoder: .init()
        )
        let endpoint = Endpoint<String>(path: "/profile")

        _ = endpoint.send(environment: environment)

        XCTAssertTrue(dataProviderUsed)
    }

    func testSendShouldUseMapResponseVariableToMapResponse() throws {
        var responseMapperUsed = false

        var endpoint = Endpoint<String>(path: "/profile")
        endpoint.mapResponse = { _, _ -> String in
            responseMapperUsed = true
            return "mapped response"
        }

        let environment = Networking.Environment(
            responseDataProvider: { _ in .just(Data()) },
            jsonDecoder: .init()
        )

        _ = try endpoint.send(environment: environment)
            .record()
            .completion
            .get()

        XCTAssertTrue(responseMapperUsed)
    }

    func testSendShouldPassEnvironmentJSONDecoderToMapResponseVariable() throws {
        class MyDecoder: JSONDecoder {}
        
        let decoder = MyDecoder()
        var actualDecoder: JSONDecoder?

        var endpoint = Endpoint<String>(path: "/profile")
        endpoint.mapResponse = { _, decoder -> String in
            actualDecoder = decoder
            return "mapped response"
        }

        let environment = Networking.Environment(
            responseDataProvider: { _ in .just(Data()) },
            jsonDecoder: decoder
        )

        _ = try endpoint.send(environment: environment)
            .record()
            .completion
            .get()

        XCTAssert(actualDecoder === decoder)
    }

    func testMakeRequestShouldCorectlyCreateRequest() throws {
        let endpoint = Endpoint<String>(
            method: .post,
            path: "/profile",
            queryItems: [
                .init(name: "foo", value: "bar"),
                .init(name: "maxCount", value: "10")
            ],
            body: "{\"foo\":\"bar\"}"
        )

        let request = try endpoint.makeRequest(.init(scheme: "http", host: "example.com", pathPrefix: "/api", apiKey: "myapikey"))

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "http://example.com/api/profile?foo=bar&maxCount=10&key=myapikey")
        XCTAssertEqual(request.httpBody, "{\"foo\":\"bar\"}".data(using: .utf8))
    }

    func testMapResponseShouldUseGivenJSONDecoderAndData() throws {
        class DecoderSpy: JSONDecoder {
            var givenData: Data?
            var givenType: Any.Type?
            override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
                givenType = type
                givenData = data
                return try super.decode(type, from: data)
            }
        }

        let decoder = DecoderSpy()
        let data = "[\"mock\",\"data\"]".data(using: .utf8)!
        let endpoint = Endpoint<[String]>(path: "/profile")

        _ = try endpoint.mapResponse(data, decoder)

        XCTAssertEqual(decoder.givenData, data)
        XCTAssert(decoder.givenType == [String].self)
    }
}

extension Networking.Environment {
    static var dummy: Self {
        .init(responseDataProvider: { _ in .just(Data()) }, jsonDecoder: JSONDecoder())
    }
}

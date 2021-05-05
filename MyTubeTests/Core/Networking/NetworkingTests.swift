//
//  NetworkingTests.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 5/3/21.
//

import XCTest
@testable import MyTube
import Combine
import CombineExpectations

class NetworkingTests: XCTestCase {
    func testSendShouldPassRequestFromRequestProviderToResponseDataProvider() {
        let request = "www.example.com/mock".request
        var actualRequest: URLRequest?

        let responseProvider: Networking.ResponseDataProvider = {
            actualRequest = $0
            return .just(Data())
        }

        _ = Networking.send({ request }, using: responseProvider, mappingWith: stubMapper)

        XCTAssertEqual(actualRequest, request)
    }

    func testSendShouldReturnErrorWhenRequestProviderFails() throws {
        let error = MockError(message: "request error")

        let completion = try Networking.send({ throw error }, using: stubDataProvider, mappingWith: stubMapper)
            .record()
            .completion
            .get()

        guard case let .failure(Networking.Error.buildRequest(actualError)) = completion else {
            XCTFail("Unexpected error thrown: \(completion)")
            return
        }
        XCTAssertEqual(actualError as? MockError, error)
    }

    func testSendShouldPassDataFromResponseProviderToMapper() throws {
        let data = "mock response".data(using: .utf8)!
        var actualData: Data?
        let mapper: Networking.ResponseDataMapper<String> = {
            actualData = $0
            return ""
        }

        _ = try Networking.send(stubRequest, using: { _ in .just(data) }, mappingWith: mapper)
            .record()
            .completion
            .get()

        XCTAssertEqual(actualData, data)
    }

    func testSendShouldReturnErrorWhenResponseProviderFails() throws {
        let error = MockError(message: "response error")

        let completion = try Networking.send(
            stubRequest,
            using: { _ in .fail(error) },
            mappingWith: stubMapper
        )
        .record()
        .completion
        .get()

        guard case let .failure(Networking.Error.getResponse(actualError)) = completion else {
            XCTFail("Unexpected error thrown: \(completion)")
            return
        }
        XCTAssertEqual(actualError as? MockError, error)
    }

    func testSendShouldReturnResultFromMapper() throws {
        struct Response: Codable, Equatable {
            let foo: String
        }
        let response = Response(foo: "bar")

        let actualResponse = try Networking.send(stubRequest, using: stubDataProvider, mappingWith: { _ in response })
        .record()
        .single
        .get()

        XCTAssertEqual(actualResponse, response)
    }

    func testSendShouldReturnErrorWhenMapperFails() throws {
        let error = MockError(message: "mapping error")

        let completion = try Networking.send(stubRequest, using: stubDataProvider, mappingWith: { _ -> String in throw error })
            .record()
            .completion
            .get()

        guard case let .failure(Networking.Error.decodeResponse(actualError)) = completion else {
            XCTFail("Unexpected error thrown: \(completion)")
            return
        }
        XCTAssertEqual(actualError as? MockError, error)
    }
}

extension NetworkingTests {
    var stubRequest: Networking.RequestProvider {
        { "www.example.com/stub".request }
    }

    var stubDataProvider:  Networking.ResponseDataProvider {
        { _ in .just(Data()) }
    }

    var stubMapper:  Networking.ResponseDataMapper<String> {
        { _ in "" }
    }
}

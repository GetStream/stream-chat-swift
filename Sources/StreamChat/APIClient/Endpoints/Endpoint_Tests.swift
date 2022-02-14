//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Endpoint_Tests: XCTestCase {
    class SomethingDecodable: Decodable {}

    func test_endpointWithoutQueryItemsNorBodyEncodingAndDecoding() {
        let endpoint = Endpoint<SomethingDecodable>.init(
            path: "some-path",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
        let encoder = JSONEncoder()
        guard let encodedEndpoint = try? encoder.encode(endpoint) else {
            XCTFail("Should properly encode the endpoint")
            return
        }

        let decoder = JSONDecoder()
        guard let decodedEndpoint = try? decoder.decode(Endpoint<SomethingDecodable>.self, from: encodedEndpoint) else {
            XCTFail("Should properly decode the endpoint")
            return
        }

        XCTAssertEqual(decodedEndpoint.path, "some-path")
        XCTAssertEqual(decodedEndpoint.method, .post)
        XCTAssertNil(decodedEndpoint.queryItems)
        XCTAssertEqual(decodedEndpoint.requiresConnectionId, false)
        XCTAssertEqual(decodedEndpoint.requiresToken, true)
        XCTAssertNil(decodedEndpoint.body)
    }

    func test_endpointWithBodyEncodingAndDecoding() {
        let endpoint = Endpoint<SomethingDecodable>.init(
            path: "some-path",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: ["BodyHello": 1]
        )
        let encoder = JSONEncoder()
        guard let encodedEndpoint = try? encoder.encode(endpoint) else {
            XCTFail("Should properly encode the endpoint")
            return
        }

        let decoder = JSONDecoder()
        guard let decodedEndpoint = try? decoder.decode(Endpoint<SomethingDecodable>.self, from: encodedEndpoint) else {
            XCTFail("Should properly decode the endpoint")
            return
        }

        XCTAssertEqual(decodedEndpoint.path, "some-path")
        XCTAssertEqual(decodedEndpoint.method, .post)
        XCTAssertNil(decodedEndpoint.queryItems)
        XCTAssertEqual(decodedEndpoint.requiresConnectionId, false)
        XCTAssertEqual(decodedEndpoint.requiresToken, true)

        guard let bodyData = decodedEndpoint.body as? Data else {
            XCTFail("Should have body")
            return
        }

        let decodedBody = try? JSONDecoder.stream.decode([String: Int].self, from: bodyData)
        XCTAssertEqual(decodedBody, ["BodyHello": 1])
    }

    func test_endpointWithQueryItemsEncodingAndDecoding() {
        let endpoint = Endpoint<SomethingDecodable>.init(
            path: "some-path",
            method: .get,
            queryItems: ["QueryHello": 2],
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
        let encoder = JSONEncoder()
        guard let encodedEndpoint = try? encoder.encode(endpoint) else {
            XCTFail("Should properly encode the endpoint")
            return
        }

        let decoder = JSONDecoder()
        guard let decodedEndpoint = try? decoder.decode(Endpoint<SomethingDecodable>.self, from: encodedEndpoint) else {
            XCTFail("Should properly decode the endpoint")
            return
        }

        XCTAssertEqual(decodedEndpoint.path, "some-path")
        XCTAssertEqual(decodedEndpoint.method, .get)
        XCTAssertNil(decodedEndpoint.body)
        XCTAssertEqual(decodedEndpoint.requiresConnectionId, false)
        XCTAssertEqual(decodedEndpoint.requiresToken, true)

        guard let queryItemsData = decodedEndpoint.queryItems as? Data else {
            XCTFail("Should have query items")
            return
        }

        let decodedQueryItems = try? JSONDecoder.stream.decode([String: Int].self, from: queryItemsData)
        XCTAssertEqual(decodedQueryItems, ["QueryHello": 2])
    }
}

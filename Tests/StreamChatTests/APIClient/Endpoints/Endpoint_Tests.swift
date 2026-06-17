//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Endpoint_Tests: XCTestCase {
    func test_withDataResponse_preservesEndpointConfiguration() {
        let endpoint = Endpoint<GetMessageResponse>(
            path: .getMessage(id: "message-id"),
            method: .get,
            queryItems: ["include_thread": "true"],
            requiresConnectionId: true,
            requiresToken: true,
            body: nil
        )

        let dataEndpoint = endpoint.withDataResponse

        XCTAssertEqual(AnyEndpoint(dataEndpoint).path.value, AnyEndpoint(endpoint).path.value)
        XCTAssertEqual(dataEndpoint.method, endpoint.method)
        XCTAssertEqual(AnyEndpoint(dataEndpoint).queryItems, AnyEndpoint(endpoint).queryItems)
        XCTAssertEqual(dataEndpoint.requiresConnectionId, endpoint.requiresConnectionId)
        XCTAssertEqual(dataEndpoint.requiresToken, endpoint.requiresToken)
    }

    func test_endpointCodable_roundTripsGeneratedPathAndMethod() throws {
        let endpoint = Endpoint<EmptyResponse>(
            path: .webSocketConnect,
            method: .post,
            queryItems: ["foo": "bar"],
            requiresConnectionId: false,
            requiresToken: false,
            body: nil
        )

        let data = try JSONEncoder.stream.encode(endpoint)
        let decoded = try JSONDecoder.stream.decode(Endpoint<EmptyResponse>.self, from: data)

        XCTAssertEqual(decoded.path.value, "/api/v2/connect")
        XCTAssertEqual(decoded.method, .post)
        let queryItemsData = try XCTUnwrap(decoded.queryItems as? Data)
        let decodedQueryItems = try JSONSerialization.jsonObject(with: queryItemsData) as? [String: Any]
        XCTAssertEqual(decodedQueryItems?["foo"] as? String, "bar")
        XCTAssertFalse(decoded.requiresConnectionId)
        XCTAssertFalse(decoded.requiresToken)
    }
}

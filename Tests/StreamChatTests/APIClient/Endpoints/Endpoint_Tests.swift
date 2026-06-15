//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Endpoint_Tests: XCTestCase {
    func test_withDataResponse_preservesEndpointConfiguration() {
        let endpoint = Endpoint<GetMessageResponse>(
            path: "/api/v2/chat/messages/message-id",
            method: .get,
            queryItems: ["include_thread": "true"],
            requiresConnectionId: true,
            requiresToken: true,
            shouldBeQueuedOffline: true,
            body: nil
        )

        let dataEndpoint = endpoint.withDataResponse

        XCTAssertEqual(AnyEndpoint(dataEndpoint).path, AnyEndpoint(endpoint).path)
        XCTAssertEqual(dataEndpoint.method, endpoint.method)
        XCTAssertEqual(dataEndpoint.queryItems, endpoint.queryItems)
        XCTAssertEqual(dataEndpoint.requiresConnectionId, endpoint.requiresConnectionId)
        XCTAssertEqual(dataEndpoint.requiresToken, endpoint.requiresToken)
        XCTAssertEqual(dataEndpoint.shouldBeQueuedOffline, endpoint.shouldBeQueuedOffline)
    }

    func test_endpointCodable_roundTripsGeneratedPathAndMethod() throws {
        let endpoint = Endpoint<EmptyResponse>(
            path: "custom/path",
            method: .post,
            queryItems: ["foo": "bar"],
            requiresConnectionId: false,
            requiresToken: false,
            shouldBeQueuedOffline: true,
            body: nil
        )

        let data = try JSONEncoder.stream.encode(endpoint)
        let decoded = try JSONDecoder.stream.decode(Endpoint<EmptyResponse>.self, from: data)

        XCTAssertEqual(decoded.path, "custom/path")
        XCTAssertEqual(decoded.method, .post)
        XCTAssertEqual(decoded.queryItems?["foo"] ?? nil, "bar")
        XCTAssertFalse(decoded.requiresConnectionId)
        XCTAssertFalse(decoded.requiresToken)
        XCTAssertTrue(decoded.shouldBeQueuedOffline)
    }
}

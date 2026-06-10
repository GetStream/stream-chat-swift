//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCompatibilityEndpoint() {
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect()

        XCTAssertEqual(endpoint.path.value, "/api/v2/connect")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
        XCTAssertNotEqual(endpoint.path.value, Endpoint<EmptyResponse>.longPoll(json: nil).path.value)
    }
}

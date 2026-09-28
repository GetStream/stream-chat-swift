//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCorrectly() {
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .custom("/api/v2/connect"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect()

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/connect", endpoint.path.value)
    }
}

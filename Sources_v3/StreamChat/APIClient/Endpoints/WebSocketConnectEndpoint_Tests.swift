//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["json": WebSocketConnectPayload(userId: userId)]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect(userId: userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

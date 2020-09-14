//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCorrectly() {
        let userId: UserId = .unique
        let userRole: UserRole = .admin
        let extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WebSocketConnectPayload(
                    userId: userId,
                    userRole: userRole,
                    extraData: extraData
                )
            ]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect(userId: userId, role: userRole, extraData: extraData)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

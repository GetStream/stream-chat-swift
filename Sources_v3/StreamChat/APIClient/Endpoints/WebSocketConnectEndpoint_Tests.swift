//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCorrectly() {
        let userId: UserId = .unique
        let userRole: UserRole = .admin
        let name = String.unique
        let imageURL = URL.unique()
        let extraData = DefaultExtraData.User.defaultValue
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WebSocketConnectPayload(
                    userId: userId,
                    name: name,
                    imageURL: imageURL,
                    userRole: userRole,
                    extraData: extraData
                )
            ]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect(
            userId: userId,
            name: name,
            imageURL: imageURL,
            role: userRole,
            extraData: extraData
        )
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCorrectly() {
        let userInfo = UserInfo<NoExtraData>(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: .defaultValue
        )
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["json": WebSocketConnectPayload(userInfo: userInfo)]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect(userInfo: userInfo)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

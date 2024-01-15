//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCorrectly() {
        let userInfo = UserInfo(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isInvisible: true,
            extraData: [:]
        )

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .connect,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["json": WebSocketConnectPayload(userInfo: userInfo)]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect(userInfo: userInfo)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("connect", endpoint.path.value)
    }
}

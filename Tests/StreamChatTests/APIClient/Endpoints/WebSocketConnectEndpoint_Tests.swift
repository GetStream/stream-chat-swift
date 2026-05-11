//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WebSocketConnectEndpoint_Tests: XCTestCase {
    func test_webSocketConnect_buildsCompatibilityEndpoint() {
        let userInfo = UserInfo(id: "user-id", name: "User", imageURL: nil, isInvisible: true, extraData: [:])

        let endpoint: Endpoint<EmptyResponse> = .webSocketConnect(userInfo: userInfo)

        XCTAssertEqual(endpoint.path.value, "connect")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }
}

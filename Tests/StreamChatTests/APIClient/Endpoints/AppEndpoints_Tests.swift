//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AppEndpoints_Tests: XCTestCase {
    func test_getApp_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetApplicationResponse> = .getApp()

        XCTAssertEqual(endpoint.path, "/api/v2/app")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AppEndpoints_Tests: XCTestCase {
    func test_getApp() throws {
        let endpoint = AnyEndpoint(Endpoint<GetApplicationResponse>.getApp())
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "/api/v2/app")
        XCTAssertEqual(endpoint.queryItems, nil)
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.body, nil)
    }
}

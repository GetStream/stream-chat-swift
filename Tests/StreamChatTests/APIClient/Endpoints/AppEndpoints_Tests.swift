//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AppEndpoints_Tests: XCTestCase {
    func test_appSettings() throws {
        let endpoint = AnyEndpoint(Endpoint<AppSettingsPayload>.appSettings())
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "app")
        XCTAssertEqual(endpoint.queryItems, nil)
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.body, nil)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_createGuest_buildsGeneratedEndpoint() {
        let request = CreateGuestRequest(user: UserRequest(id: "guest-id", name: "Guest"))
        let endpoint: Endpoint<CreateGuestResponse> = .createGuest(createGuestRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/guest")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertFalse(endpoint.requiresToken)
        XCTAssertEqual(endpoint.body as? CreateGuestRequest, request)
    }
}

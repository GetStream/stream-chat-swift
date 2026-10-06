//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_token_buildsCorrectly_withCustomExtraData() {
        let request = CreateGuestRequest(
            user: UserRequest(
                custom: ["company": .string("getstream.io")],
                id: .unique,
                image: .unique,
                name: .unique
            )
        )
        let expectedEndpoint = Endpoint<CreateGuestResponse>(
            path: .createGuest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: request
        )

        let actualEndpoint: Endpoint<CreateGuestResponse> = .createGuest(createGuestRequest: request)

        // Assert endpoint is built correctly
        XCTAssertEqual(
            AnyEndpoint(expectedEndpoint),
            AnyEndpoint(actualEndpoint)
        )
        XCTAssertEqual("/api/v2/guest", actualEndpoint.path.value)
        XCTAssertFalse(actualEndpoint.requiresToken)
    }
}

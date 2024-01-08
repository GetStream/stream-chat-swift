//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_token_buildsCorrectly_withDefaultExtraData() {
        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: [:]
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: payload.userId,
            name: payload.name,
            imageURL: payload.imageURL,
            extraData: [:]
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(
            AnyEndpoint(expectedEndpoint),
            AnyEndpoint(actualEndpoint)
        )
        XCTAssertEqual("guest", actualEndpoint.path.value)
    }

    func test_token_buildsCorrectly_withCustomExtraData() {
        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: [:]
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: payload.userId,
            name: payload.name,
            imageURL: payload.imageURL,
            extraData: [:]
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(
            AnyEndpoint(expectedEndpoint),
            AnyEndpoint(actualEndpoint)
        )
        XCTAssertEqual("guest", actualEndpoint.path.value)
    }
}

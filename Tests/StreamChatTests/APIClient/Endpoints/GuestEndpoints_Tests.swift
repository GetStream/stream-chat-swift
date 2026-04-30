//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_token_buildsCorrectly_withDefaultExtraData() {
        let userId: UserId = .unique
        let name: String = .unique
        let imageURL: URL = .unique()
        let payload = GuestUserTokenRequestPayload(
            userId: userId,
            name: name,
            imageURL: imageURL,
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
            userId: userId,
            name: name,
            imageURL: imageURL,
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
        let userId: UserId = .unique
        let name: String = .unique
        let imageURL: URL = .unique()
        let extraData: [String: RawJSON] = ["company": .string("getstream.io")]
        let payload = GuestUserTokenRequestPayload(
            userId: userId,
            name: name,
            imageURL: imageURL,
            extraData: extraData
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: userId,
            name: name,
            imageURL: imageURL,
            extraData: extraData
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(
            AnyEndpoint(expectedEndpoint),
            AnyEndpoint(actualEndpoint)
        )
        XCTAssertEqual("guest", actualEndpoint.path.value)
    }
}

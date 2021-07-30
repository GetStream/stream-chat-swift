//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_token_buildsCorrectly_withDefaultExtraData() {
        let extraData = CustomData.defaultValue

        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: extraData
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload>(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: payload.userId,
            name: payload.name,
            imageURL: payload.imageURL,
            extraData: extraData
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(
            AnyEndpoint(expectedEndpoint),
            AnyEndpoint(actualEndpoint)
        )
    }
    
    func test_token_buildsCorrectly_withCustomExtraData() {
        let extraData: CustomData = ["company": .string("getstream.io")]

        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: extraData
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload>(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: payload.userId,
            name: payload.name,
            imageURL: payload.imageURL,
            extraData: extraData
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(
            AnyEndpoint(expectedEndpoint),
            AnyEndpoint(actualEndpoint)
        )
    }
}

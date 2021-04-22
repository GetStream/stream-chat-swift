//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_token_buildsCorrectly_withDefaultExtraData() {
        let extraData = NoExtraData.defaultValue

        let payload = GuestUserTokenRequestPayload<NoExtraData>(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: extraData
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload<NoExtraData>>(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload<NoExtraData>> = .guestUserToken(
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
        let extraData = TestExtraData.User(company: "getstream.io")

        let payload = GuestUserTokenRequestPayload<TestExtraData>(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: extraData
        )
        let expectedEndpoint = Endpoint<GuestUserTokenPayload<TestExtraData>>(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )

        let actualEndpoint: Endpoint<GuestUserTokenPayload<TestExtraData>> = .guestUserToken(
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

private struct TestExtraData: ExtraDataTypes {
    struct User: UserExtraData {
        static var defaultValue = Self(company: "Stream")
        let company: String
    }
}

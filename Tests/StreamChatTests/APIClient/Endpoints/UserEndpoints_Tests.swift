//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserEndpoints_Tests: XCTestCase {
    func test_users_buildsCorrectly() {
        let query: UserListQuery = .init(
            filter: .equal(.id, to: .unique),
            sort: [.init(key: .lastActivityAt)]
        )

        let expectedEndpoint = Endpoint<UserListPayload>(
            path: .users,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            body: ["payload": query]
        )

        // Build endpoint
        let endpoint: Endpoint<UserListPayload> = .users(query: query)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("users", endpoint.path.value)
    }

    func test_updateCurrentUser_buildsCorrectly() {
        let userId = UserId.unique
        let payload: UserUpdateRequestBody = .init(
            name: .unique,
            imageURL: .unique(),
            privacySettings: .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true)
            ),
            role: .anonymous,
            extraData: ["company": .string(.unique)]
        )

        let users: [String: AnyEncodable] = [
            "id": AnyEncodable(userId),
            "set": AnyEncodable(payload)
        ]
        let body: [String: AnyEncodable] = [
            "users": AnyEncodable([users])
        ]

        let expectedEndpoint = Endpoint<CurrentUserUpdateResponse>(
            path: .users,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )

        let endpoint: Endpoint<CurrentUserUpdateResponse> = .updateUser(id: userId, payload: payload)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("users", endpoint.path.value)
    }

    func test_unread_buildsCorrectly() {
        let expectedEndpoint = Endpoint<CurrentUserUnreadsPayload>(
            path: .unread,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<CurrentUserUnreadsPayload> = .unreads()

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual(endpoint.path.value, "unread")
    }
}

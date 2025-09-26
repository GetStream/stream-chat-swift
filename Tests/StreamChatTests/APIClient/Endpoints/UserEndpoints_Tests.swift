//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
            teamsRole: ["ios": "guest"],
            extraData: ["company": .string(.unique)]
        )
        let unset = ["image", "name"]

        let users: [String: AnyEncodable] = [
            "id": AnyEncodable(userId),
            "set": AnyEncodable(payload),
            "unset": AnyEncodable(unset)
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

        let endpoint: Endpoint<CurrentUserUpdateResponse> = .updateUser(id: userId, payload: payload, unset: unset)

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

    func test_pushPreferences_buildsCorrectly() {
        let preferences: [PushPreferenceRequestPayload] = [
            .init(
                chatLevel: "mentions",
                channelId: nil,
                disabledUntil: nil,
                removeDisable: true
            ),
            .init(
                chatLevel: "all",
                channelId: "messaging:test-channel",
                disabledUntil: Date(timeIntervalSince1970: 1_609_459_200),
                removeDisable: nil
            )
        ]

        let expectedEndpoint = Endpoint<PushPreferencesPayloadResponse>(
            path: .pushPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "preferences": AnyEncodable(preferences)
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<PushPreferencesPayloadResponse> = .pushPreferences(preferences)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual(endpoint.path.value, "push_preferences")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
}

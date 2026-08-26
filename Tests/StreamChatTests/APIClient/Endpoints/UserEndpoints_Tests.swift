//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let expectedEndpoint = Endpoint<CurrentUserUnreads>(
            path: .unreadCounts,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<CurrentUserUnreads> = .unreadCounts()

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/unread")
    }

    func test_pushPreferences_buildsCorrectly() {
        let request = UpsertPushPreferencesRequest(preferences: [
            PushPreferenceInput(chatLevel: .directMentions, removeDisable: true),
            PushPreferenceInput(
                channelCid: "messaging:test-channel",
                chatLevel: .all,
                disabledUntil: Date(timeIntervalSince1970: 1_609_459_200)
            )
        ])

        let expectedEndpoint = Endpoint<UpsertPushPreferencesResponse>(
            path: .updatePushNotificationPreferences,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )

        // Build endpoint
        let endpoint: Endpoint<UpsertPushPreferencesResponse> = .updatePushNotificationPreferences(upsertPushPreferencesRequest: request)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual(endpoint.path.value, "/api/v2/push_preferences")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
}

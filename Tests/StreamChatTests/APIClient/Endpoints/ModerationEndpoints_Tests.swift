//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
    func test_muteUser_buildsCorrectly() {
        let userId: UserId = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .muteUser(true),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .muteUser(userId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/mute", endpoint.path.value)
    }

    func test_unmuteUser_buildsCorrectly() {
        let userId: UserId = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .muteUser(false),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .unmuteUser(userId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/unmute", endpoint.path.value)
    }

    func test_banMember_buildsCorrectly() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .banMember,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelMemberBanRequestPayload(
                userId: userId,
                cid: cid,
                shadow: false,
                timeoutInMinutes: timeoutInMinutes,
                reason: reason
            )
        )

        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .banMember(
            userId,
            cid: cid,
            shadow: false,
            timeoutInMinutes: timeoutInMinutes,
            reason: reason
        )

        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/ban", endpoint.path.value)
    }

    func test_unbanMember_buildsCorrectly() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .banMember,
            method: .delete,
            queryItems: ChannelMemberUnbanRequestPayload(
                userId: userId,
                cid: cid
            ),
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .unbanMember(userId, cid: cid)

        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/ban", endpoint.path.value)
    }

    func test_flagUser_buildsCorrectly() {
        let testCases = [
            (true, EndpointPath.flagUser(true)),
            (false, EndpointPath.flagUser(false))
        ]

        for (flag, path) in testCases {
            let userId: UserId = .unique
            let reason: String = .unique
            let extraData: [String: RawJSON] = ["key": .string(.unique)]
            let body = FlagRequestBody(
                reason: reason,
                targetMessageId: nil,
                targetUserId: userId,
                custom: extraData
            )
            let expectedEndpoint = Endpoint<FlagUserPayload>(
                path: path,
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: body
            )

            // Build endpoint.
            let endpoint: Endpoint<FlagUserPayload> = .flagUser(
                flag,
                with: userId,
                reason: reason,
                extraData: extraData
            )

            // Assert endpoint is built correctly.
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(flag ? "moderation/flag" : "moderation/unflag", endpoint.path.value)
        }
    }

    func test_flagMessage_buildsCorrectly() {
        let testCases = [
            (true, EndpointPath.flagMessage(true)),
            (false, EndpointPath.flagMessage(false))
        ]

        for (flag, path) in testCases {
            let messageId: MessageId = .unique
            let reason: String = .unique
            let extraData: [String: RawJSON] = ["key": .string(.unique)]
            let body = FlagRequestBody(
                reason: reason,
                targetMessageId: messageId,
                targetUserId: nil,
                custom: extraData
            )
            let expectedEndpoint = Endpoint<FlagMessagePayload>(
                path: path,
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: body
            )

            // Build endpoint.
            let endpoint: Endpoint<FlagMessagePayload> = .flagMessage(flag, with: messageId, reason: reason, extraData: extraData)

            // Assert endpoint is built correctly.
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(flag ? "moderation/flag" : "moderation/unflag", endpoint.path.value)
        }
    }
    
    func test_blockUser_buildsCorrectly() {
        let userId: UserId = .unique

        let expectedEndpoint = Endpoint<BlockingUserPayload>(
            path: .blockUser,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["blocked_user_id": userId]
        )

        // Build endpoint
        let endpoint: Endpoint<BlockingUserPayload> = .blockUser(userId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("users/block", endpoint.path.value)
    }

    func test_unblockUser_buildsCorrectly() {
        let userId: UserId = .unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .unblockUser,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["blocked_user_id": userId]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .unblockUser(userId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("users/unblock", endpoint.path.value)
    }
}

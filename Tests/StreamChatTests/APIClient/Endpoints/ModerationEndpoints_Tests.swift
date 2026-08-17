//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
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
    
    func test_blockUsers_buildsCorrectly() {
        let userId: UserId = .unique

        let expectedEndpoint = Endpoint<BlockUsersResponse>(
            path: .blockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: BlockUsersRequest(blockedUserId: userId)
        )

        // Build endpoint
        let endpoint = Endpoint<BlockUsersResponse>.blockUsers(blockUsersRequest: BlockUsersRequest(blockedUserId: userId))

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/users/block", endpoint.path.value)
    }

    func test_unblockUsers_buildsCorrectly() {
        let userId: UserId = .unique

        let expectedEndpoint = Endpoint<UnblockUsersResponse>(
            path: .unblockUsers,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: UnblockUsersRequest(blockedUserId: userId)
        )

        // Build endpoint
        let endpoint = Endpoint<UnblockUsersResponse>.unblockUsers(unblockUsersRequest: UnblockUsersRequest(blockedUserId: userId))

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/users/unblock", endpoint.path.value)
    }

    func test_getBlockedUsers_buildsCorrectly() {
        let expectedEndpoint = Endpoint<GetBlockedUsersResponse>(
            path: .getBlockedUsers,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint = Endpoint<GetBlockedUsersResponse>.getBlockedUsers()

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/users/block", endpoint.path.value)
    }
}

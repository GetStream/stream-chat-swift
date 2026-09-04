//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
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

//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class User_Tests: XCTestCase {
    func test_isDeactivated_userWithoutDeactivatedAt_returnsFalse() throws {
        let user = ChatUser(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isOnline: true,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            teamsRole: nil,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            teams: [],
            language: nil,
            avgResponseTime: nil,
            extraData: [:]
        )

        XCTAssertFalse(user.isDeactivated)
    }

    func test_isDeactivated_userWithDeactivatedAt_returnsTrue() throws {
        let user = ChatUser(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isOnline: true,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            teamsRole: nil,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: Date(),
            lastActiveAt: .unique,
            teams: [],
            language: nil,
            avgResponseTime: nil,
            extraData: [:]
        )

        XCTAssertTrue(user.isDeactivated)
    }
}

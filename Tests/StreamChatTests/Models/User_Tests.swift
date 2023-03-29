//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            teams: [],
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
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: Date(),
            lastActiveAt: .unique,
            teams: [],
            extraData: [:]
        )

        XCTAssertTrue(user.isDeactivated)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class UserListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<UserListFilterScope, T>

    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertEqual(Key<UserId>.id.rawValue, "id")
        XCTAssertEqual(Key<String>.name.rawValue, "name")
        XCTAssertEqual(Key<URL>.imageURL.rawValue, "image")
        XCTAssertEqual(Key<UserRole>.role.rawValue, "role")
        XCTAssertEqual(Key<Bool>.isOnline.rawValue, "online")
        XCTAssertEqual(Key<Bool>.isBanned.rawValue, "banned")
        XCTAssertEqual(Key<Date>.createdAt.rawValue, "created_at")
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, "updated_at")
        XCTAssertEqual(Key<Date>.lastActiveAt.rawValue, "last_active")
        XCTAssertEqual(Key<Bool>.isInvisible.rawValue, "invisible")
        XCTAssertEqual(Key<Int>.unreadChannelsCount.rawValue, "unread_channels")
        XCTAssertEqual(Key<Int>.unreadMessagesCount.rawValue, "total_unread_count")
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, "anon")
        XCTAssertEqual(Key<TeamId>.teams.rawValue, "teams")
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class MemberListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<MemberListFilterScope, T>

    func test_filterKeys_matchChannelCodingKeys() {
        // Member specific coding keys
        XCTAssertEqual(Key<Bool>.isModerator.rawValue, "is_moderator")
        XCTAssertEqual(Key<String>.email.rawValue, "user.email")
        XCTAssertEqual(Key<MemberRole>.channelRole.rawValue, "channel_role")

        // User-related coding keys
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
    }
}

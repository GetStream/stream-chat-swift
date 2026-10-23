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
        XCTAssertEqual(Key<UserId>.id.rawValue, StringCodingKey.id.stringValue)
        XCTAssertEqual(Key<String>.name.rawValue, StringCodingKey.name.stringValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, StringCodingKey.image.stringValue)
        XCTAssertEqual(Key<UserRole>.role.rawValue, StringCodingKey.role.stringValue)
        XCTAssertEqual(Key<Bool>.isOnline.rawValue, StringCodingKey.online.stringValue)
        XCTAssertEqual(Key<Bool>.isBanned.rawValue, StringCodingKey.banned.stringValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, StringCodingKey.createdAt.stringValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, StringCodingKey.updatedAt.stringValue)
        XCTAssertEqual(Key<Date>.lastActiveAt.rawValue, StringCodingKey.lastActive.stringValue)
        XCTAssertEqual(Key<Bool>.isInvisible.rawValue, StringCodingKey.invisible.stringValue)
        XCTAssertEqual(Key<Int>.unreadChannelsCount.rawValue, StringCodingKey.unreadChannels.stringValue)
        XCTAssertEqual(Key<Int>.unreadMessagesCount.rawValue, StringCodingKey.totalUnreadCount.stringValue)
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, "anon")
    }
}

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
        XCTAssertEqual(Key<UserId>.id.rawValue, FullUserResponse.CodingKeys.id.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, FullUserResponse.CodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, FullUserResponse.CodingKeys.image.rawValue)
        XCTAssertEqual(Key<UserRole>.role.rawValue, FullUserResponse.CodingKeys.role.rawValue)
        XCTAssertEqual(Key<Bool>.isOnline.rawValue, FullUserResponse.CodingKeys.online.rawValue)
        XCTAssertEqual(Key<Bool>.isBanned.rawValue, FullUserResponse.CodingKeys.banned.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, FullUserResponse.CodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, FullUserResponse.CodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.lastActiveAt.rawValue, FullUserResponse.CodingKeys.lastActive.rawValue)
        XCTAssertEqual(Key<Bool>.isInvisible.rawValue, FullUserResponse.CodingKeys.invisible.rawValue)
        XCTAssertEqual(Key<Int>.unreadChannelsCount.rawValue, FullUserResponse.CodingKeys.unreadChannels.rawValue)
        XCTAssertEqual(Key<Int>.unreadMessagesCount.rawValue, FullUserResponse.CodingKeys.totalUnreadCount.rawValue)
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, "anon")
    }
}

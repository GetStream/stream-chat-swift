//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class MemberListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<MemberListFilterScope, T>

    func test_filterKeys_matchChannelCodingKeys() {
        // Member specific coding keys
        XCTAssertEqual(Key<Bool>.isModerator.rawValue, "is_moderator")

        // User-related coding keys
        XCTAssertEqual(Key<UserId>.id.rawValue, UserPayloadsCodingKeys.id.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, UserPayloadsCodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, UserPayloadsCodingKeys.imageURL.rawValue)
        XCTAssertEqual(Key<UserRole>.role.rawValue, UserPayloadsCodingKeys.role.rawValue)
        XCTAssertEqual(Key<Bool>.isOnline.rawValue, UserPayloadsCodingKeys.isOnline.rawValue)
        XCTAssertEqual(Key<Bool>.isBanned.rawValue, UserPayloadsCodingKeys.isBanned.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, UserPayloadsCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, UserPayloadsCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.lastActiveAt.rawValue, UserPayloadsCodingKeys.lastActiveAt.rawValue)
        XCTAssertEqual(Key<Bool>.isInvisible.rawValue, UserPayloadsCodingKeys.isInvisible.rawValue)
        XCTAssertEqual(Key<Int>.unreadChannelsCount.rawValue, UserPayloadsCodingKeys.unreadChannelsCount.rawValue)
        XCTAssertEqual(Key<Int>.unreadMessagesCount.rawValue, UserPayloadsCodingKeys.unreadMessagesCount.rawValue)
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, UserPayloadsCodingKeys.isAnonymous.rawValue)
    }
}

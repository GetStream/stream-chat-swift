//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class UserListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<UserListFilterScope, T>

    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<UserId>.id.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<String>.name.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<URL>.imageURL.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<UserRole>.role.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Bool>.isOnline.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Bool>.isBanned.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Date>.createdAt.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Date>.updatedAt.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Date>.lastActiveAt.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Bool>.isInvisible.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Int>.unreadChannelsCount.rawValue))
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<Int>.unreadMessagesCount.rawValue))
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, "anon")
        XCTAssertTrue(FullUserResponse.allKeys.contains(Key<TeamId>.teams.rawValue))
    }
}

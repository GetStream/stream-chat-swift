//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class ChannelListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<ChannelListFilterScope<NoExtraData>, T>
    
    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertEqual(Key<ChannelId>.cid.rawValue, ChannelCodingKeys.cid.rawValue)
        XCTAssertEqual(Key<ChannelType>.type.rawValue, ChannelCodingKeys.typeRawValue.rawValue)
        XCTAssertEqual(Key<Date>.lastMessageAt.rawValue, ChannelCodingKeys.lastMessageAt.rawValue)
        XCTAssertEqual(Key<UserId>.createdBy.rawValue, ChannelCodingKeys.createdBy.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, ChannelCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, ChannelCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.deletedAt.rawValue, ChannelCodingKeys.deletedAt.rawValue)
        XCTAssertEqual(Key<Bool>.frozen.rawValue, ChannelCodingKeys.frozen.rawValue)
        XCTAssertEqual(Key<Int>.memberCount.rawValue, ChannelCodingKeys.memberCount.rawValue)
    }

    func test_filterKeys_matchNameAndImageExtraDataCodingKeys() {
        XCTAssertEqual(
            FilterKey<ChannelListFilterScope<NameAndImageExtraData>, String>.name.rawValue,
            NameAndImageExtraData.CodingKeys.name.rawValue
        )
        XCTAssertEqual(
            FilterKey<ChannelListFilterScope<NameAndImageExtraData>, URL>.imageURL.rawValue,
            NameAndImageExtraData.CodingKeys.imageURL.rawValue
        )
    }

    func test_containMembersHelper() {
        // Check the `containMembers` helper translates to `members $in [ids]`
        let ids: [UserId] = [.unique, .unique]
        XCTAssertEqual(
            Filter<ChannelListFilterScope<NoExtraData>>.containMembers(userIds: ids),
            Filter<ChannelListFilterScope<NoExtraData>>.in(.members, values: ids)
        )
    }
}

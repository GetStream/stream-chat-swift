//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChannelListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<ChannelListFilterScope<NoExtraData>, T>
    
    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertEqual(Key<ChannelId>.cid.rawValue, ChannelCodingKeys.cid.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, ChannelCodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, ChannelCodingKeys.imageURL.rawValue)
        XCTAssertEqual(Key<ChannelType>.type.rawValue, ChannelCodingKeys.typeRawValue.rawValue)
        XCTAssertEqual(Key<Date>.lastMessageAt.rawValue, ChannelCodingKeys.lastMessageAt.rawValue)
        XCTAssertEqual(Key<UserId>.createdBy.rawValue, ChannelCodingKeys.createdBy.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, ChannelCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, ChannelCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.deletedAt.rawValue, ChannelCodingKeys.deletedAt.rawValue)
        XCTAssertEqual(Key<Bool>.frozen.rawValue, ChannelCodingKeys.frozen.rawValue)
        XCTAssertEqual(Key<Int>.memberCount.rawValue, ChannelCodingKeys.memberCount.rawValue)
    }

    func test_containMembersHelper() {
        // Check the `containMembers` helper translates to `members $in [ids]`
        let ids: [UserId] = [.unique, .unique]
        XCTAssertEqual(
            Filter<ChannelListFilterScope<NoExtraData>>.containMembers(userIds: ids),
            Filter<ChannelListFilterScope<NoExtraData>>.in(.members, values: ids)
        )
    }
    
    func test_safeSorting_added() {
        // Sortings without safe option
        let sortings: [[Sorting<ChannelListSortingKey>]] = [
            [.init(key: .createdAt)],
            [.init(key: .updatedAt), .init(key: .memberCount)]
        ]
        
        // Create queries with sortings
        let queries = sortings.map {
            ChannelListQuery(filter: .containMembers(userIds: [.unique]), sort: $0)
        }
        
        // Assert safe sorting option is added
        queries.forEach {
            XCTAssertEqual($0.sort.last?.key, Sorting<ChannelListSortingKey>(key: .cid).key)
        }
    }
}

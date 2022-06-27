//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ChannelListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<ChannelListFilterScope, T>

    func test_filterKeys_matchChannelCodingKeys() {
        // FilterKeys that exists in ChannelCodingKeys
        XCTAssertEqual(Key<ChannelId>.cid.rawValue, ChannelCodingKeys.cid.rawValue)
        XCTAssertEqual(Key<String>.id.rawValue, ChannelCodingKeys.id.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, ChannelCodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, ChannelCodingKeys.imageURL.rawValue)
        XCTAssertEqual(Key<ChannelType>.type.rawValue, ChannelCodingKeys.typeRawValue.rawValue)
        XCTAssertEqual(Key<Date>.lastMessageAt.rawValue, ChannelCodingKeys.lastMessageAt.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, ChannelCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, ChannelCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.deletedAt.rawValue, ChannelCodingKeys.deletedAt.rawValue)
        XCTAssertEqual(Key<Bool>.frozen.rawValue, ChannelCodingKeys.frozen.rawValue)
        XCTAssertEqual(Key<Int>.memberCount.rawValue, ChannelCodingKeys.memberCount.rawValue)
        XCTAssertEqual(Key<TeamId>.team.rawValue, ChannelCodingKeys.team.rawValue)
        
        // FilterKeys without corresponding ChannelCodingKeys
        XCTAssertEqual(Key<UserId>.createdBy.rawValue, "created_by_id")
        XCTAssertEqual(Key<Bool>.joined.rawValue, "joined")
        XCTAssertEqual(Key<Bool>.muted.rawValue, "muted")
        XCTAssertEqual(Key<InviteFilterValue>.invite.rawValue, "invite")
        XCTAssertEqual(Key<String>.memberName.rawValue, "member.user.name")
        XCTAssertEqual(Key<Date>.lastUpdatedAt.rawValue, "last_updated")
    }

    func test_containMembersHelper() {
        // Check the `containMembers` helper translates to `members $in [ids]`
        let ids: [UserId] = [.unique, .unique]
        XCTAssertEqual(
            Filter<ChannelListFilterScope>.containMembers(userIds: ids),
            Filter<ChannelListFilterScope>.in(.members, values: ids)
        )
    }
    
    func test_noTeam_helper() {
        XCTAssertEqual(
            Filter<ChannelListFilterScope>.noTeam,
            Filter<ChannelListFilterScope>.equal(.team, to: nil)
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

    func test_hiddenFilter_valueIsDetected() {
        let hiddenValue = Bool.random()
        let testValues: [(Filter<ChannelListFilterScope>, Bool?)] = [
            (.equal(.hidden, to: hiddenValue), hiddenValue),
            (.containMembers(userIds: [.unique]), nil),
            (.autocomplete(.cid, text: .unique), nil),
            (.and([.exists(.imageURL), .autocomplete(.name, text: .unique)]), nil),
            (.and([.exists(.imageURL), .equal(.hidden, to: hiddenValue)]), hiddenValue),
            (.and([.exists(.imageURL), .or([.autocomplete(.name, text: .unique), .equal(.hidden, to: hiddenValue)])]), hiddenValue),
            (.and([.exists(.imageURL), .or([.autocomplete(.name, text: .unique), .equal(.frozen, to: true)])]), nil)
        ]

        for testValue in testValues {
            XCTAssertEqual(testValue.0.hiddenFilterValue, testValue.1, "\(testValue) failed")
        }
    }

    func test_debugDescription() {
        let id = "theid"
        let query = ChannelListQuery(
            filter: .containMembers(userIds: [id]),
            sort: [Sorting<ChannelListSortingKey>(key: .cid)],
            pageSize: 1,
            messagesLimit: 2,
            membersLimit: 3
        )

        XCTAssertEqual(query.debugDescription, "Filter: members IN [\"theid\"] | Sort: [cid:-1]")
    }
}

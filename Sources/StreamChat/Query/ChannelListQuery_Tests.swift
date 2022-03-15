//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChannelListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<ChannelListFilterScope, T>
    
    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertEqual(Key<ChannelId>.cid.rawValue, ChannelCodingKeys.cid.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, ChannelCodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, ChannelCodingKeys.imageURL.rawValue)
        XCTAssertEqual(Key<ChannelType>.type.rawValue, ChannelCodingKeys.typeRawValue.rawValue)
        XCTAssertEqual(Key<Date>.lastMessageAt.rawValue, ChannelCodingKeys.lastMessageAt.rawValue)
        XCTAssertEqual(Key<UserId>.createdBy.rawValue, "created_by_id")
        XCTAssertEqual(Key<Date>.createdAt.rawValue, ChannelCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, ChannelCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.deletedAt.rawValue, ChannelCodingKeys.deletedAt.rawValue)
        XCTAssertEqual(Key<Bool>.frozen.rawValue, ChannelCodingKeys.frozen.rawValue)
        XCTAssertEqual(Key<Int>.memberCount.rawValue, ChannelCodingKeys.memberCount.rawValue)
        XCTAssertEqual(Key<TeamId>.team.rawValue, ChannelCodingKeys.team.rawValue)
    }

    func test_containMembersHelper() {
        // Check the `containMembers` helper translates to `members $in [ids]`
        let ids: [UserId] = [.unique, .unique]
        XCTAssertEqual(
            Filter<ChannelListFilterScope>.containMembers(userIds: ids),
            Filter<ChannelListFilterScope>.in(.members, values: ids)
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

final class ChannelListQuery_Tests: XCTestCase {
    func test_channelListQuery_encodedCorrectly() throws {
        let cid = ChannelId.unique
        let filter = Filter<ChannelListFilterScope>.equal(.cid, to: cid)
        let sort = Sorting<ChannelListSortingKey>.init(key: .cid)
        let pageSize = Int.channelsPageSize
        let messagesLimit = Int.messagesPageSize
        let membersLimit = Int.channelMembersPageSize
        
        // Create ChannelListQuery
        var query = ChannelListQuery(
            filter: filter,
            sort: [sort],
            pageSize: pageSize,
            messagesLimit: messagesLimit,
            membersLimit: membersLimit
        )
        query.options = .watch
        
        let expectedData: [String: Any] = [
            "limit": pageSize,
            "message_limit": messagesLimit,
            "member_limit": membersLimit,
            "sort": [["field": "cid", "direction": -1]],
            "filter_conditions": ["cid": ["$eq": cid.rawValue]],
            "watch": true
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        
        // Assert ChannelListQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}

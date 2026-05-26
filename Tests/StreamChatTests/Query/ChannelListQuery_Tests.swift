//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

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
            "sort": [["field": "cid", "direction": -1] as [String: Any]],
            "filter_conditions": ["cid": ["$eq": cid.rawValue]],
            "watch": true
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert ChannelListQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_runtimeSortingValues_returnsEmptyIfNoCustomKey() {
        let sorting = [
            Sorting(key: ChannelListSortingKey.updatedAt),
            Sorting(key: ChannelListSortingKey.memberCount)
        ]
        let query = ChannelListQuery(
            filter: .noTeam,
            sort: sorting
        )

        XCTAssertTrue(query.runtimeSortingValues.isEmpty)
    }

    func test_runtimeSortingValues_runtimeSorting_returnsArrayIfCustomKey() {
        let sorting = [
            Sorting(key: ChannelListSortingKey.updatedAt),
            Sorting(key: ChannelListSortingKey.memberCount),
            Sorting(key: ChannelListSortingKey.custom(keyPath: \.customScore, key: "score"))
        ]
        let query = ChannelListQuery(
            filter: .noTeam,
            sort: sorting
        )

        let runtimeSorting = query.runtimeSortingValues
        XCTAssertEqual(runtimeSorting.count, 3)
    }

    func test_channelListQuery_predefinedFilter_encodedCorrectly() throws {
        let pageSize = Int.channelsPageSize
        var query = ChannelListQuery(
            predefinedFilter: "user_messaging_channels",
            filterValues: ["user_id": "user123"],
            sortValues: ["sort_field": "last_message_at"],
            pageSize: pageSize
        )
        query.options = .watch

        let expectedData: [String: Any] = [
            "limit": pageSize,
            "predefined_filter": "user_messaging_channels",
            "filter_values": ["user_id": "user123"],
            "sort_values": ["sort_field": "last_message_at"],
            "watch": true
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_channelListQuery_predefinedFilter_omitsEmptyValueDictionaries() throws {
        let pageSize = Int.channelsPageSize
        var query = ChannelListQuery(
            predefinedFilter: "user_messaging_channels",
            pageSize: pageSize
        )
        query.options = .watch

        let expectedData: [String: Any] = [
            "limit": pageSize,
            "predefined_filter": "user_messaging_channels",
            "watch": true
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_channelListQuery_predefinedFilter_setsExpectedProperties() {
        let query = ChannelListQuery(
            predefinedFilter: "team_channels",
            filterValues: ["channel_type": "messaging"],
            sortValues: ["sort_field": "created_at"]
        )

        XCTAssertEqual(query.predefinedFilter, "team_channels")
        XCTAssertEqual(query.filterValues?["channel_type"], "messaging")
        XCTAssertEqual(query.sortValues?["sort_field"], "created_at")
        XCTAssertTrue(query.sort.isEmpty)
    }

    func test_channelListQuery_traditionalInit_leavesPredefinedFieldsNil() {
        let query = ChannelListQuery(filter: .equal(.cid, to: .unique))

        XCTAssertNil(query.predefinedFilter)
        XCTAssertNil(query.filterValues)
        XCTAssertNil(query.sortValues)
    }

    // MARK: - queryHash

    func test_queryHash_traditionalQuery_equalsFilterFilterHash() {
        let filter = Filter<ChannelListFilterScope>.equal(.cid, to: .unique)
        let query = ChannelListQuery(filter: filter)

        XCTAssertEqual(query.queryHash, filter.filterHash)
    }

    func test_queryHash_predefinedQuery_isStableAcrossKeyOrdering() {
        let queryA = ChannelListQuery(
            predefinedFilter: "team_channels",
            filterValues: ["channel_type": "messaging", "team_name": "engineering", "user_id": "user123"],
            sortValues: ["primary_sort": "last_message_at", "secondary_sort": "created_at"]
        )
        let queryB = ChannelListQuery(
            predefinedFilter: "team_channels",
            filterValues: ["user_id": "user123", "team_name": "engineering", "channel_type": "messaging"],
            sortValues: ["secondary_sort": "created_at", "primary_sort": "last_message_at"]
        )

        XCTAssertEqual(queryA.queryHash, queryB.queryHash)
    }

    func test_queryHash_predefinedQuery_differsWhenFilterValuesDiffer() {
        let queryA = ChannelListQuery(
            predefinedFilter: "user_messaging_channels",
            filterValues: ["user_id": "user123"]
        )
        let queryB = ChannelListQuery(
            predefinedFilter: "user_messaging_channels",
            filterValues: ["user_id": "user456"]
        )

        XCTAssertNotEqual(queryA.queryHash, queryB.queryHash)
    }

    func test_queryHash_predefinedQuery_differsFromTraditionalQuery() {
        let predefinedQuery = ChannelListQuery(predefinedFilter: "user_messaging_channels")
        let traditionalQuery = ChannelListQuery(filter: .and([]))

        XCTAssertNotEqual(predefinedQuery.queryHash, traditionalQuery.queryHash)
    }

    func test_channelListQuery_encodedOmitsLimitsWhenNil() throws {
        let cid = ChannelId.unique
        let filter = Filter<ChannelListFilterScope>.equal(.cid, to: cid)
        let sort = Sorting<ChannelListSortingKey>.init(key: .cid)
        let pageSize = Int.channelsPageSize

        var query = ChannelListQuery(
            filter: filter,
            sort: [sort],
            pageSize: pageSize,
            messagesLimit: nil,
            membersLimit: nil
        )
        query.options = .watch

        let expectedData: [String: Any] = [
            "limit": pageSize,
            "sort": [["field": "cid", "direction": -1] as [String: Any]],
            "filter_conditions": ["cid": ["$eq": cid.rawValue]],
            "watch": true
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}

private extension ChatChannel {
    var customScore: Double {
        extraData["score"]?.numberValue ?? 0
    }
}

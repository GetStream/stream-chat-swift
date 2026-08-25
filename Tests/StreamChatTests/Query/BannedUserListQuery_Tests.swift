//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class BannedUserListQuery_Tests: XCTestCase {
    // MARK: - Initialization

    func test_defaultInitialization() {
        let query = BannedUserListQuery()

        XCTAssertNil(query.filter)
        XCTAssertTrue(query.sort.isEmpty)
        XCTAssertEqual(query.pagination.pageSize, 30)
        XCTAssertEqual(query.pagination.offset, 0)
        XCTAssertFalse(query.excludeExpiredBans)
    }

    func test_customInitialization() {
        let filter = Filter<BannedUserListFilterScope>.equal(.userId, to: "luke")
        let sort = [Sorting<BannedUserListSortingKey>(key: .createdAt, isAscending: true)]

        let query = BannedUserListQuery(
            filter: filter,
            sort: sort,
            pagination: Pagination(pageSize: 10, offset: 20),
            excludeExpiredBans: true
        )

        XCTAssertEqual(query.filter?.filterHash, filter.filterHash)
        XCTAssertEqual(query.sort.count, 1)
        XCTAssertEqual(query.sort[0].key, .createdAt)
        XCTAssertTrue(query.sort[0].isAscending)
        XCTAssertEqual(query.pagination.pageSize, 10)
        XCTAssertEqual(query.pagination.offset, 20)
        XCTAssertTrue(query.excludeExpiredBans)
    }

    // MARK: - Encoding

    func test_encode_withAllFields() throws {
        let cid: ChannelId = .init(type: .messaging, id: "123")
        let query = BannedUserListQuery(
            filter: .equal(.cid, to: cid),
            sort: [.init(key: .createdAt, isAscending: true)],
            pagination: Pagination(pageSize: 10, offset: 20),
            excludeExpiredBans: true
        )

        let expectedData: [String: Any] = [
            "filter_conditions": ["channel_cid": ["$eq": cid.rawValue]],
            "sort": [["field": "created_at", "direction": 1]],
            "limit": 10,
            "offset": 20,
            "exclude_expired_bans": true
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_encode_withDefaultFields() throws {
        let query = BannedUserListQuery(pagination: Pagination(pageSize: 10))

        let expectedData: [String: Any] = ["limit": 10]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    // MARK: - Payload

    func test_asQueryBannedUsersPayload_whenAllFieldsAreSet() throws {
        let cid: ChannelId = .unique
        let query = BannedUserListQuery(
            filter: .equal(.cid, to: cid),
            sort: [.init(key: .createdAt, isAscending: false)],
            pagination: Pagination(pageSize: 25, offset: 50),
            excludeExpiredBans: true
        )

        let payload = query.asQueryBannedUsersPayload()

        XCTAssertEqual(payload.limit, 25)
        XCTAssertEqual(payload.offset, 50)
        XCTAssertEqual(payload.excludeExpiredBans, true)
        XCTAssertEqual(payload.sort?.count, 1)
        XCTAssertEqual(payload.sort?.first?.field, "created_at")
        XCTAssertEqual(payload.sort?.first?.direction, -1)
        AssertJSONEqual(
            try JSONEncoder.default.encode(payload.filterConditions),
            ["channel_cid": ["$eq": cid.rawValue]]
        )
    }

    func test_asQueryBannedUsersPayload_whenOnlyDefaultFieldsAreSet() throws {
        let query = BannedUserListQuery(pagination: Pagination(pageSize: 30))

        let payload = query.asQueryBannedUsersPayload()

        XCTAssertEqual(payload.limit, 30)
        XCTAssertNil(payload.offset)
        XCTAssertNil(payload.excludeExpiredBans)
        XCTAssertNil(payload.sort)
        AssertJSONEqual(try JSONEncoder.default.encode(payload.filterConditions), [String: Any]())
    }

    // MARK: - Channel scoped query

    func test_channelBans_whenAdditionalFilterIsNil_thenFiltersByChannelOnly() throws {
        let cid: ChannelId = .unique

        let query = BannedUserListQuery.channelBans(
            cid: cid,
            filter: nil,
            sort: [],
            pagination: Pagination(pageSize: 30),
            excludeExpiredBans: false
        )

        AssertJSONEqual(
            try JSONEncoder.default.encode(query.asQueryBannedUsersPayload().filterConditions),
            ["channel_cid": ["$eq": cid.rawValue]]
        )
    }

    func test_channelBans_whenAdditionalFilterIsSet_thenCombinesBothFilters() throws {
        let cid: ChannelId = .unique

        let query = BannedUserListQuery.channelBans(
            cid: cid,
            filter: .equal(.bannedById, to: "leia"),
            sort: [],
            pagination: Pagination(pageSize: 30),
            excludeExpiredBans: false
        )

        let expectedFilter: [String: Any] = [
            "$and": [
                ["channel_cid": ["$eq": cid.rawValue]],
                ["banned_by_id": ["$eq": "leia"]]
            ]
        ]
        AssertJSONEqual(
            try JSONEncoder.default.encode(query.asQueryBannedUsersPayload().filterConditions),
            try JSONSerialization.data(withJSONObject: expectedFilter, options: [])
        )
    }

    func test_channelBans_forwardsSortPaginationAndExcludeExpiredBans() {
        let query = BannedUserListQuery.channelBans(
            cid: .unique,
            filter: nil,
            sort: [.init(key: .createdAt, isAscending: true)],
            pagination: Pagination(pageSize: 15, offset: 5),
            excludeExpiredBans: true
        )

        XCTAssertEqual(query.sort.count, 1)
        XCTAssertEqual(query.sort[0].key, .createdAt)
        XCTAssertTrue(query.sort[0].isAscending)
        XCTAssertEqual(query.pagination.pageSize, 15)
        XCTAssertEqual(query.pagination.offset, 5)
        XCTAssertTrue(query.excludeExpiredBans)
    }
}

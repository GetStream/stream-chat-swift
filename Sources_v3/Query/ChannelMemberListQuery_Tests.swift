//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class ChannelMemberListQuery_Tests: XCTestCase {
    func test_query_isEncodedCorrectly() throws {
        // Create the query.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .contains("name", "a"),
            sort: [.init(key: .createdAt, isAscending: true)],
            pagination: [.offset(3)]
        )

        // Encode the query.
        let json = try JSONEncoder.default.encode(query)

        // Assert query is encoded correctly.
        AssertJSONEqual(json, [
            "id": query.cid.id,
            "type": query.cid.type.rawValue,
            "filter_conditions": ["name": ["$contains": "a"]],
            "sort": [["key": "created_at", "direction": 1]] as NSArray,
            "offset": 3
        ])
    }
    
    func test_hash_isCalculatedCorrectly() {
        // Create the query.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .contains("name", "a"),
            sort: [.init(key: .createdAt, isAscending: true)]
        )
        
        let expectedHash = [
            query.cid.rawValue,
            query.filter?.filterHash ?? Filter.nilFilterHash,
            query.sort.map(\.description).joined()
        ].joined(separator: "-")
        
        // Assert queryHash is calculated correctly.
        XCTAssertEqual(query.queryHash, expectedHash)
    }
    
    func test_emptySorting_isNotEncoded() throws {
        // Create the query without any sort options.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .contains("name", "a"),
            pagination: [.offset(3)]
        )

        // Encode the query.
        let json = try JSONEncoder.default.encode(query)

        // Assert encoding does not contain `sort` key.
        AssertJSONEqual(json, [
            "id": query.cid.id,
            "type": query.cid.type.rawValue,
            "filter_conditions": ["name": ["$contains": "a"]],
            "offset": 3
        ])
    }
    
    func test_defaultPageSizeIsUsed_ifNotSpecified() throws {
        // Create the query with default params.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .contains("name", "a")
        )

        // Encode the query.
        let json = try JSONEncoder.default.encode(query)

        // Assert encoding does not contain `sort` key AND has default page size.
        AssertJSONEqual(json, [
            "id": query.cid.id,
            "type": query.cid.type.rawValue,
            "filter_conditions": ["name": ["$contains": "a"]],
            "limit": PaginationOption.channelMembersPageSize.limit!
        ])
    }
    
    func test_singleMemberQuery_worksCorrectly() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        let actual = ChannelMemberListQuery.channelMember(userId: userId, cid: cid)
        let actualJSON = try JSONEncoder.default.encode(actual)

        let expected = ChannelMemberListQuery(cid: cid, filter: .equal("id", to: userId))
        let expectedJSON = try JSONEncoder.default.encode(expected)
    
        // Assert queries match
        AssertJSONEqual(actualJSON, expectedJSON)
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

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

final class ChannelMemberListQuery_Tests: XCTestCase {
    func test_query_isEncodedCorrectly() throws {
        // Create the query.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .equal(.id, to: "luke"),
            sort: [.init(key: .createdAt, isAscending: true)]
        )

        // Encode the query.
        let json = try JSONEncoder.default.encode(query)

        // Assert query is encoded correctly.
        AssertJSONEqual(json, [
            "id": query.cid.id,
            "type": query.cid.type.rawValue,
            "sort": [["field": "created_at", "direction": 1]] as NSArray,
            "filter_conditions": ["id": ["$eq": "luke"]],
            "limit": 30
        ])
    }
    
    func test_hash_isCalculatedCorrectly() {
        // Create the query.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .equal(.id, to: "luke"),
            sort: [.init(key: .createdAt, isAscending: true)]
        )
        
        let expectedHash = [
            query.cid.rawValue,
            query.filter!.filterHash,
            query.sort.map(\.description).joined()
        ].joined(separator: "-")
        
        // Assert queryHash is calculated correctly.
        XCTAssertEqual(query.queryHash, expectedHash)
    }
    
    func test_emptySorting_isNotEncoded() throws {
        // Create the query without any sort options.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .equal(.id, to: "luke")
        )

        // Encode the query.
        let json = try JSONEncoder.default.encode(query)

        // Assert encoding does not contain `sort` key.
        AssertJSONEqual(json, [
            "id": query.cid.id,
            "type": query.cid.type.rawValue,
            "filter_conditions": ["id": ["$eq": "luke"]],
            "limit": 30
        ])
    }
    
    func test_defaultPageSizeIsUsed_ifNotSpecified() throws {
        // Create the query with default params.
        let query = ChannelMemberListQuery(
            cid: .unique,
            filter: .equal(.id, to: "luke")
        )

        // Encode the query.
        let json = try JSONEncoder.default.encode(query)

        // Assert encoding does not contain `sort` key AND has default page size.
        AssertJSONEqual(json, [
            "id": query.cid.id,
            "type": query.cid.type.rawValue,
            "filter_conditions": ["id": ["$eq": "luke"]],
            "limit": Int.channelMembersPageSize
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

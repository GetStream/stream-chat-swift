//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

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
    
    // MARK: - Sort by `createdAt`
    
    func test_sortingByCreatedAt_ascending() throws {
        // Declare some channel member payloads
        let member1: MemberPayload = .dummy()
        let member2: MemberPayload = .dummy(
            createdAt: member1.createdAt.addingTimeInterval(10)
        )
        
        // Declare channel payload
        let channel: ChannelDetailPayload = .dummy(
            cid: .unique,
            members: [member1, member2]
        )
        
        // Declare channel list query sorting by `createdAt` ascending
        let memberListQuery = ChannelMemberListQuery(
            cid: channel.cid,
            sort: [.init(key: .createdAt, isAscending: true)]
        )
        
        // Create database container
        let database = try DatabaseContainerMock(kind: .inMemory)
        
        try database.writeSynchronously { session in
            // Save channel to database
            try session.saveChannel(payload: channel, query: nil)
            
            // Save members to database in random order and link to query
            try channel.members?.shuffled().forEach {
                try session.saveMember(
                    payload: $0,
                    channelId: channel.cid,
                    query: memberListQuery
                )
            }
        }
        
        // Fetch channel members matching the query
        let fetchedMembers = try database.viewContext.fetch(
            MemberDTO.members(matching: memberListQuery)
        )
        
        // Assert members order is correct
        XCTAssertEqual(
            [member1.user.id, member2.user.id],
            fetchedMembers.map(\.user.id)
        )
    }
    
    func test_sortingByCreatedAt_descending() throws {
        // Declare some channel member payloads
        let member1: MemberPayload = .dummy()
        let member2: MemberPayload = .dummy(
            createdAt: member1.createdAt.addingTimeInterval(10)
        )
        
        // Declare channel payload
        let channel: ChannelDetailPayload = .dummy(
            cid: .unique,
            members: [member1, member2]
        )
        
        // Declare channel list query sorting by `createdAt` descending
        let memberListQuery = ChannelMemberListQuery(
            cid: channel.cid,
            sort: [.init(key: .createdAt, isAscending: false)]
        )
        
        // Create database container
        let database = try DatabaseContainerMock(kind: .inMemory)
        
        try database.writeSynchronously { session in
            // Save channel to database
            try session.saveChannel(payload: channel, query: nil)
            
            // Save members to database in random order and link to query
            try channel.members?.shuffled().forEach {
                try session.saveMember(
                    payload: $0,
                    channelId: channel.cid,
                    query: memberListQuery
                )
            }
        }
        
        // Fetch channel members matching the query
        let fetchedMembers = try database.viewContext.fetch(
            MemberDTO.members(matching: memberListQuery)
        )
        
        // Assert members order is correct
        XCTAssertEqual(
            [member2.user.id, member1.user.id],
            fetchedMembers.map(\.user.id)
        )
    }
    
    // MARK: - Sort by `name`
    
    func test_sortingByName_ascending() throws {
        // Declare some channel member payloads
        let member1: MemberPayload = .dummy(user: .dummy(userId: .unique, name: "A"))
        let member2: MemberPayload = .dummy(user: .dummy(userId: .unique, name: "B"))
        
        // Declare channel payload
        let channel: ChannelDetailPayload = .dummy(
            cid: .unique,
            members: [member1, member2]
        )
        
        // Declare channel list query sorting by `name` ascending
        let memberListQuery = ChannelMemberListQuery(
            cid: channel.cid,
            sort: [.init(key: .name, isAscending: true)]
        )
        
        // Create database container
        let database = try DatabaseContainerMock(kind: .inMemory)
        
        try database.writeSynchronously { session in
            // Save channel to database
            try session.saveChannel(payload: channel, query: nil)
            
            // Save members to database in random order and link to query
            try channel.members?.shuffled().forEach {
                try session.saveMember(
                    payload: $0,
                    channelId: channel.cid,
                    query: memberListQuery
                )
            }
        }
        
        // Fetch channel members matching the query
        let fetchedMembers = try database.viewContext.fetch(
            MemberDTO.members(matching: memberListQuery)
        )
        
        // Assert members order is correct
        XCTAssertEqual(
            [member1.user.id, member2.user.id],
            fetchedMembers.map(\.user.id)
        )
    }
    
    func test_sortingByName_descending() throws {
        // Declare some channel member payloads
        let member1: MemberPayload = .dummy(
            user: .dummy(userId: .unique, name: "A")
        )
        let member2: MemberPayload = .dummy(
            user: .dummy(userId: .unique, name: "B"),
            createdAt: member1.createdAt.addingTimeInterval(10)
        )
        let member3: MemberPayload = .dummy(
            user: .dummy(userId: .unique, name: "B"),
            createdAt: member1.createdAt.addingTimeInterval(-10)
        )
        
        // Declare channel payload
        let channel: ChannelDetailPayload = .dummy(
            cid: .unique,
            members: [member1, member2, member3]
        )
        
        // Declare channel list query sorting by `name` and `createdAt`
        let memberListQuery = ChannelMemberListQuery(
            cid: channel.cid,
            sort: [
                .init(key: .name, isAscending: true),
                .init(key: .createdAt, isAscending: true)
            ]
        )
        
        // Create database container
        let database = try DatabaseContainerMock(kind: .inMemory)
        
        try database.writeSynchronously { session in
            // Save channel to database
            try session.saveChannel(payload: channel, query: nil)
            
            // Save members to database in random order and link to query
            try channel.members?.shuffled().forEach {
                try session.saveMember(
                    payload: $0,
                    channelId: channel.cid,
                    query: memberListQuery
                )
            }
        }
        
        // Fetch channel members matching the query
        let fetchedMembers = try database.viewContext.fetch(
            MemberDTO.members(matching: memberListQuery)
        )
        
        // Assert members order is correct
        XCTAssertEqual(
            [member1.user.id, member3.user.id, member2.user.id],
            fetchedMembers.map(\.user.id)
        )
    }
    
    // MARK: - Sort by multiple options
    
    func test_sortingByNameThenCreatedAt() throws {
        // Declare some channel member payloads
        let member1: MemberPayload = .dummy(
            user: .dummy(userId: .unique, name: "A")
        )
        let member2: MemberPayload = .dummy(
            user: .dummy(userId: .unique, name: "B"),
            createdAt: member1.createdAt.addingTimeInterval(10)
        )
        let member3: MemberPayload = .dummy(
            user: .dummy(userId: .unique, name: "B"),
            createdAt: member1.createdAt.addingTimeInterval(-10)
        )
        
        // Declare channel payload
        let channel: ChannelDetailPayload = .dummy(
            cid: .unique,
            members: [
                member1,
                member2,
                member3
            ]
        )
        
        // Declare channel list query sorting by `name` and `createdAt`
        let memberListQuery = ChannelMemberListQuery(
            cid: channel.cid,
            sort: [
                .init(key: .name, isAscending: true),
                .init(key: .createdAt, isAscending: true)
            ]
        )
        
        // Create database container
        let database = try DatabaseContainerMock(kind: .inMemory)
        
        try database.writeSynchronously { session in
            // Save channel to database
            try session.saveChannel(payload: channel, query: nil)
            
            // Save members to database in random order and link to query
            try channel.members?.shuffled().forEach {
                try session.saveMember(
                    payload: $0,
                    channelId: channel.cid,
                    query: memberListQuery
                )
            }
        }
        
        // Fetch channel members matching the query
        let fetchedMemberIDs = try database
            .viewContext
            .fetch(MemberDTO.members(matching: memberListQuery))
            .map { $0.asModel().id }
        
        // Assert members order is correct
        XCTAssertEqual(
            [member1.user.id, member3.user.id, member2.user.id],
            fetchedMemberIDs
        )
    }
}

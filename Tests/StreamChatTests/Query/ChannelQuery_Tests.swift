//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelQuery_Tests: XCTestCase {
    // Test ChannelQuery encoded correctly
    func test_channelQuery_encodedCorrectly() throws {
        let cid: ChannelId = .unique
        let paginationParameter: PaginationParameter = .lessThan("testId")
        let membersLimit = 10
        let watchersLimit = 10

        // Create ChannelQuery
        let query = ChannelQuery(
            cid: cid,
            paginationParameter: paginationParameter,
            membersLimit: membersLimit,
            watchersLimit: watchersLimit
        )

        let expectedData: [String: Any] = [
            "presence": true,
            "watch": true,
            "state": true,
            "messages": ["limit": 25, "id_lt": "testId"] as [String: Any],
            "members": ["limit": 10],
            "watchers": ["limit": 10]
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert ChannelQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_apiPath() {
        // Create query without id specified
        let query1: ChannelQuery = .init(channelPayload: .init(
            type: .messaging,
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [.unique],
            invites: [],
            filterTags: [],
            extraData: [:]
        ))

        // Assert only type is part of path
        XCTAssertEqual(query1.apiPath, "\(query1.type)")

        // Create query with id and type specified
        let cid: ChannelId = .unique
        let query2: ChannelQuery = .init(cid: cid)

        // Assert type and id are part of path
        XCTAssertEqual(query2.apiPath, "\(query2.type.rawValue)/\(query2.id!)")
    }

    func test_apiPath_customType() {
        let query: ChannelQuery = .init(channelPayload: .init(
            type: .custom("custom_type"),
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [.unique],
            invites: [],
            filterTags: [],
            extraData: [:]
        ))
        XCTAssertEqual(query.apiPath, "custom_type")
    }

    func test_apiPath_customTypeAndId() {
        let query: ChannelQuery = .init(channelPayload: .init(
            cid: .init(type: .custom("custom_type"), id: "id"),
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [.unique],
            invites: [],
            filterTags: [],
            extraData: [:]
        ))
        XCTAssertEqual(query.apiPath, "custom_type/id")
    }

    func test_channelQuery_encodesMemberCustomInclude() throws {
        var query = ChannelQuery(cid: .unique, pageSize: 25)
        query.options = [.state]
        query.memberCustomInclude = ["badge", "tier"]

        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(encodedJSON, [
            "state": true,
            "messages": ["limit": 25],
            "member_custom_include": ["badge", "tier"] as NSArray
        ])
    }

    func test_channelQuery_omitsMemberCustomIncludeWhenNilOrEmpty() throws {
        var query = ChannelQuery(cid: .unique, pageSize: 25)
        query.options = [.state]
        query.memberCustomInclude = nil

        var encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(encodedJSON, [
            "state": true,
            "messages": ["limit": 25]
        ])

        query.memberCustomInclude = []
        encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(encodedJSON, [
            "state": true,
            "messages": ["limit": 25]
        ])
    }

    func test_channelQuery_preservesMemberCustomIncludeWhenCopyingCid() {
        var original = ChannelQuery(cid: .unique)
        original.memberCustomInclude = ["badge"]

        let copied = ChannelQuery(cid: .unique, channelQuery: original)
        XCTAssertEqual(copied.memberCustomInclude, ["badge"])
    }
}

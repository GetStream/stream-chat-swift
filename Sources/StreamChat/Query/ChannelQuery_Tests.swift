//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChannelQuery_Tests: XCTestCase {
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
            "messages": ["limit": 25, "id_lt": "testId"],
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
            extraData: [:]
        ))
        XCTAssertEqual(query.apiPath, "custom_type/id")
    }
}

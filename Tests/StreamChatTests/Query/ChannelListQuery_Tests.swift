//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

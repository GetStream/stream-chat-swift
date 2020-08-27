//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ChannelQuery_Tests: XCTestCase {
    // Test ChannelQuery encoded correctly
    func test_channelQuery_encodedCorreclty() throws {
        let cid: ChannelId = .unique
        let messagesPagination = Pagination(arrayLiteral: .offset(3))
        let membersPagination = Pagination(arrayLiteral: .offset(4))
        let watchersPagination = Pagination(arrayLiteral: .offset(5))
        let options: QueryOptions = .all

        // Create ChannelQuery
        let query = ChannelQuery<DefaultDataTypes>(
            cid: cid,
            messagesPagination: messagesPagination,
            membersPagination: membersPagination,
            watchersPagination: watchersPagination,
            options: options
        )

        let expectedData: [String: Any] = [
            "presence": true,
            "watch": true,
            "state": true,
            "messages": ["offset": 3],
            "members": ["offset": 4],
            "watchers": ["offset": 5]
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert ChannelQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}

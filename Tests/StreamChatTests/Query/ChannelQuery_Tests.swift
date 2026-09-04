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

    func test_endpoint_backendDefaultWatchersLimit_omitsLimit() throws {
        let query = ChannelQuery(cid: .unique, watchersLimit: .backendDefaultPageSize)

        let request = try XCTUnwrap(query.endpoint.body as? ChannelGetOrCreateRequest)
        let json = try JSONEncoder.default.encode(request)

        AssertJSONEqual(json, [
            "messages": ["limit": 25],
            "presence": true,
            "state": true,
            "watch": true,
            "watchers": [:]
        ])
    }
}

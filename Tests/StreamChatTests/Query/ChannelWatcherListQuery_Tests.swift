//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelWatcherListQuery_Tests: XCTestCase {
    func test_query_isEncodedCorrectly() throws {
        // Create the query.
        let query = ChannelWatcherListQuery(
            cid: .unique,
            pagination: .init(
                pageSize: .random(in: 1...100),
                offset: .random(in: 10...100)
            )
        )
        
        // Encode the query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert query is encoded correctly.
        AssertJSONEqual(json, [
            "state": true,
            "watch": true,
            "watchers": ["limit": query.pagination.pageSize, "offset": query.pagination.offset]
        ])
    }
    
    func test_defaultPageSizeIsUsed_ifNotSpecified() throws {
        // Create the query.
        let query = ChannelWatcherListQuery(cid: .unique)
        
        // Encode the query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert query is encoded correctly.
        AssertJSONEqual(json, [
            "state": true,
            "watch": true,
            "watchers": ["limit": Int.channelWatchersPageSize]
        ])
    }
}

//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class Sorting_Tests: XCTestCase {
    func test_Encoding() throws {
        let sorting = Sorting<ChannelListSortingKey>(key: .cid, isAscending: true)
        
        let expectedData: [String: Any] = [
            "field": "cid",
            "direction": 1
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(sorting)

        // Assert Sorting encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class Sorting_Tests: XCTestCase {
    func test_Encoding() throws {
        let sorting = Sorting<ChannelListSortingKey>(key: .createdAt, isAscending: true)
        
        let expectedData: [String: Any] = [
            "field": "created_at",
            "direction": 1
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(sorting)

        // Assert Sorting encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}

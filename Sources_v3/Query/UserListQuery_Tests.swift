//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class UserListQuery_Tests: XCTestCase {
    // Test UserListQuery encoded correctly
    func test_UserListQuery_encodedCorrectly() throws {
        let filter: Filter = .contains("name", "a")
        let sort: [Sorting<UserListSortingKey>] = [.init(key: .lastActivityAt)]
        let pagination: Pagination = .init(arrayLiteral: .offset(3))

        // Create UserListQuery
        let query = UserListQuery(
            filter: filter,
            sort: sort,
            pagination: pagination
        )

        let expectedData: [String: Any] = [
            "presence": true,
            "offset": 3,
            "filter_conditions": ["name": ["$contains": "a"]],
            "sort": [["field": "last_active", "direction": -1]]
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert UserListQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_singleUserQuery_worksCorrectly() throws {
        let userId: UserId = .unique
        
        let actual = UserListQuery.user(withID: userId)
        let actualJSON = try JSONEncoder.default.encode(actual)

        let expected = UserListQuery(filter: .equal("id", to: userId))
        let expectedJSON = try JSONEncoder.default.encode(expected)
    
        // Assert queries match
        AssertJSONEqual(actualJSON, expectedJSON)
    }
}

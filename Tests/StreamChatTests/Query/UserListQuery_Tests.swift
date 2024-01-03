//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserListQuery_Tests: XCTestCase {
    // Test UserListQuery encoded correctly
    func test_UserListQuery_encodedCorrectly() throws {
        let filter: Filter<UserListFilterScope> = .equal(.id, to: "luke")
        let sort: [Sorting<UserListSortingKey>] = [.init(key: .lastActivityAt)]

        // Create UserListQuery
        let query = UserListQuery(
            filter: filter,
            sort: sort,
            pageSize: 23
        )

        let expectedData: [String: Any] = [
            "presence": true,
            "limit": 23,
            "filter_conditions": ["id": ["$eq": "luke"]],
            "sort": [["field": "last_active", "direction": -1] as [String: Any]]
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

    func test_searchQuery_whenNilSearchTermIsGiven_fallbacksToFilterEveryUserMatchesTo() {
        // Declare search query with nil search term
        let query: UserListQuery = .search(term: nil)

        // Assert filter all users match to is used
        XCTAssertEqual(query.filter, .exists(.id))
    }

    func test_searchQuery_whenEmptySearchTermIsGiven_fallbacksToFilterEveryUserMatchesTo() {
        // Declare search query with empty search term
        let query: UserListQuery = .search(term: "")

        // Assert filter all users match to is used
        XCTAssertEqual(query.filter, .exists(.id))
    }

    func test_searchQuery_whenValidSearchTermIsGiven_usesAutocompletionFilter() {
        // Declare search term
        let searchTerm: String = .unique

        // Declare search query with the given search term
        let query: UserListQuery = .search(term: searchTerm)

        // Assert autocompletion filter is used
        XCTAssertEqual(query.filter, .or([
            .autocomplete(.name, text: searchTerm),
            .autocomplete(.id, text: searchTerm)
        ]))
    }

    func test_searchQuery_alwaysSortsByName() {
        for searchTerm in [nil, "", .unique] {
            // Declare a query with the given search term
            let query: UserListQuery = .search(term: searchTerm)

            // Assert query sorts users by name ascending
            XCTAssertTrue(query.sort.contains(.init(key: .name, isAscending: true)))
        }
    }
}

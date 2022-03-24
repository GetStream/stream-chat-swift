//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class UserListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<UserListFilterScope, T>
    
    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertEqual(Key<UserId>.id.rawValue, UserPayloadsCodingKeys.id.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, UserPayloadsCodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, UserPayloadsCodingKeys.imageURL.rawValue)
        XCTAssertEqual(Key<UserRole>.role.rawValue, UserPayloadsCodingKeys.role.rawValue)
        XCTAssertEqual(Key<Bool>.isOnline.rawValue, UserPayloadsCodingKeys.isOnline.rawValue)
        XCTAssertEqual(Key<Bool>.isBanned.rawValue, UserPayloadsCodingKeys.isBanned.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, UserPayloadsCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, UserPayloadsCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.lastActiveAt.rawValue, UserPayloadsCodingKeys.lastActiveAt.rawValue)
        XCTAssertEqual(Key<Bool>.isInvisible.rawValue, UserPayloadsCodingKeys.isInvisible.rawValue)
        XCTAssertEqual(Key<Int>.unreadChannelsCount.rawValue, UserPayloadsCodingKeys.unreadChannelsCount.rawValue)
        XCTAssertEqual(Key<Int>.unreadMessagesCount.rawValue, UserPayloadsCodingKeys.unreadMessagesCount.rawValue)
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, UserPayloadsCodingKeys.isAnonymous.rawValue)
        XCTAssertEqual(Key<TeamId>.teams.rawValue, UserPayloadsCodingKeys.teams.rawValue)
    }
}

class UserListQuery_Tests: XCTestCase {
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
            "sort": [["field": "last_active", "direction": -1], ["field": "id", "direction": -1]]
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
    
    func test_safeSorting_added() {
        // Sortings without safe option
        let sortings: [[Sorting<UserListSortingKey>]] = [
            [.init(key: .lastActivityAt)],
            [.init(key: .lastActivityAt), .init(key: .isBanned)]
        ]
        
        // Create queries with sortings
        let queries = sortings.map { UserListQuery(sort: $0) }
        
        // Assert safe sorting option is added
        queries.forEach {
            XCTAssertEqual($0.sort.last?.key, Sorting<UserListSortingKey>(key: .id).key)
        }
    }
}

//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftListQuery_Tests: XCTestCase {
    func test_defaultInitialization() {
        let query = DraftListQuery()
        
        XCTAssertEqual(query.pagination.pageSize, 25)
        XCTAssertEqual(query.pagination.offset, 0)
        XCTAssertEqual(query.sorting.count, 1)
        XCTAssertEqual(query.sorting[0].key, .createdAt)
        XCTAssertFalse(query.sorting[0].isAscending)
    }
    
    func test_customInitialization() {
        let pagination = Pagination(pageSize: 10, offset: 5)
        let sorting = [Sorting<DraftListSortingKey>(key: .createdAt, isAscending: true)]
        
        let query = DraftListQuery(pagination: pagination, sorting: sorting)
        
        XCTAssertEqual(query.pagination.pageSize, 10)
        XCTAssertEqual(query.pagination.offset, 5)
        XCTAssertEqual(query.sorting.count, 1)
        XCTAssertEqual(query.sorting[0].key, .createdAt)
        XCTAssertTrue(query.sorting[0].isAscending)
    }
    
    func test_encode() throws {
        let query = DraftListQuery(
            pagination: .init(pageSize: 20, offset: 10),
            sorting: [.init(key: .createdAt, isAscending: true)]
        )
        
        let expectedData: [String: Any] = [
            "offset": 10,
            "limit": 20,
            "sort": [["field": "created_at", "direction": 1]]
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_encode_withoutSorting() throws {
        let query = DraftListQuery(
            pagination: .init(pageSize: 20, offset: 10),
            sorting: []
        )
        
        let expectedData: [String: Any] = [
            "offset": 10,
            "limit": 20
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class Pagination_Tests: XCTestCase {
    func test_invalidMessagesPaginationInit_returnsNil() {
        let pagination = MessagesPagination(pageSize: nil, parameter: nil)
        
        // Assert initializer returns nil on invalid pagination
        XCTAssertNil(pagination)
    }
    
    func test_pagination_Encoding() throws {
        var pagination = Pagination(pageSize: 10, offset: 10)
        
        // Mock expected JSON object
        var expectedData: [String: Any] = [
            "limit": 10,
            "offset": 10
        ]
        
        var encodedJSON = try JSONEncoder.default.encode(pagination)
        var expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert `Pagination` encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
        
        pagination = Pagination(pageSize: 10)
        
        // Mock expected JSON object
        expectedData = [
            "limit": 10
        ]
        
        encodedJSON = try JSONEncoder.default.encode(pagination)
        expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert `Pagination` encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
    }
    
    func test_messagesPagination_Encoding() throws {
        // Create pagination
        let pagination = MessagesPagination(pageSize: .channelMembersPageSize, parameter: .lessThan("testId"))
        
        // Mock expected JSON object
        let expectedData: [String: Any] = [
            "limit": 30,
            "id_lt": "testId"
        ]
        
        let encodedJSON = try JSONEncoder.default.encode(pagination)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert `MessagesPagination` encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Pagination_Tests: XCTestCase {
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

    func test_encoding_withAroundId() throws {
        let pagination = MessagesPagination(pageSize: 25, parameter: .around("someId"))

        let expectedData: [String: Any] = [
            "limit": 25,
            "id_around": "someId"
        ]

        let encodedJSON = try JSONEncoder.default.encode(pagination)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert `MessagesPagination` encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
    }

    func test_aroundMessageId() {
        let aroundPagination = MessagesPagination(pageSize: 25, parameter: .around("someId"))
        XCTAssertEqual(aroundPagination.parameter?.aroundMessageId, "someId")

        let greaterPagination = MessagesPagination(pageSize: 25, parameter: .greaterThan("someId"))
        XCTAssertEqual(greaterPagination.parameter?.aroundMessageId, nil)
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class FilterDecoding_Tests: XCTestCase {
    // MARK: - Exception thrown tests

    func testFilterDecodingThrowExceptionOnEmpty() {
        checkDecodingFilterThrowException(json: "")
    }

    func testFilterDecodingThrowExceptionOnInvalidJSON() {
        checkDecodingFilterThrowException(json: "12345")
    }

    func testFilterDecodingThrowExceptionOnInvalidKeylessJSON() {
        checkDecodingFilterThrowException(json: #"{"value"}"#)
    }

    func testFilterRightSideDecodingThrowExceptionWithMoreThanOneKey() {
        let filterJson = #"{"test_key":{"$eq":"test_value_1","$ne":"test_value_2"}}"#
        checkDecodingFilterThrowException(json: filterJson)
    }

    func testFilterRightSideDecodingThrowExceptionWithoutOperationKey() {
        let filterJson = #"{"test_key":{"eq":"test_value_1"}}"#
        checkDecodingFilterThrowException(json: filterJson)
    }

    func testFilterRightSideDecodingThrowExceptionOnNonExistingOperation() {
        let filterJson = #"{"test_key":{"$myspecialOperation":"test_value_1"}}"#
        checkDecodingFilterThrowException(json: filterJson)
    }

    // MARK: - Correct decoded tests

    func testFilterDecoding() {
        // Given
        let testCases = FilterCodingTestPair.allCases
        for pair in testCases {
            // When
            let decoded: Filter<FilterTestScope> = try! pair.json.deserializeFilterThrows()
            // Then
            XCTAssertEqual(decoded, pair.filter)
        }
    }

    // MARK: - Private methods

    private func checkDecodingFilterThrowException(json: String) {
        do {
            // When
            let _: Filter<FilterTestScope> = try json.deserializeFilterThrows()
        } catch {
            // Then
            XCTAssertNotNil(error)
        }
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FilterDecoding_Tests: XCTestCase {
    // MARK: - Exception thrown tests

    func test_throwsException_whenFilterDecodesEmptyJSON() {
        checkDecodingFilterThrowException(json: "")
    }

    func test_throwsException_whenFilterDecodesInvalidJSON() {
        checkDecodingFilterThrowException(json: "12345")
    }

    func test_throwsException_whenFilterDecodesInvalidKeylessJSON() {
        checkDecodingFilterThrowException(json: #"{"value"}"#)
    }

    func test_throwsException_whenFilterRightSideDecodesJSONWithMoreThanOneKey() {
        let filterJson = #"{"test_key":{"$eq":"test_value_1","$ne":"test_value_2"}}"#
        checkDecodingFilterThrowException(json: filterJson)
    }

    func test_throwsException_whenFilterRightSideDecodesWithoutOperationKey() {
        let filterJson = #"{"test_key":{"eq":"test_value_1"}}"#
        checkDecodingFilterThrowException(json: filterJson)
    }

    func test_throwsException_whenFilterRightSideDecodesNonExistingOperation() {
        let filterJson = #"{"test_key":{"$myspecialOperation":"test_value_1"}}"#
        checkDecodingFilterThrowException(json: filterJson)
    }

    // MARK: - Correct decoded tests

    func test_decodesFilter_whenCorrectJSONIsPassed() {
        // Given
        let testCases = FilterCodingTestPair.allCases
        for pair in testCases {
            // When
            let decoded: Filter<FilterTestScope> = try! pair.json.deserializeFilterThrows()
            // Then
            XCTAssertEqual(decoded, pair.filter)
        }
    }
}

// MARK: Test Helpers

extension FilterDecoding_Tests {
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

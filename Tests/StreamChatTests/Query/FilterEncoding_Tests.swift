//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FilterEncoding_Tests: XCTestCase {
    func test_filterEncodes_whenNotDoubles() throws {
        // Given
        let testCases = FilterCodingTestPair.allCases
        for pair in testCases {
            // When
            let encoded = try XCTUnwrap(pair.filter.serializedThrows().data(using: .utf8))
            // Then
            let jsonData = try XCTUnwrap(pair.json.data(using: .utf8))
            let jsonObject = try XCTUnwrap(try JSONSerialization.jsonObject(with: jsonData) as? [String: Any])
            AssertJSONEqual(encoded, jsonObject)
        }
    }
}

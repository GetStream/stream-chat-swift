//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FilterEncoding_Tests: XCTestCase {
    func testFilterEncodingNotDoubles() {
        // Given
        let testCases = FilterCodingTestPair.allCases
        for pair in testCases {
            // When
            let encoded = try! pair.filter.serializedThrows()
            // Then
            XCTAssertEqual(encoded, pair.json)
        }
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class LazyCachedMapCollection_Tests: XCTestCase {
    func test_equalByTransformedContent() {
        // Arrange: Prepare two lazy sequences that gives same result but have different sources and transformations
        let s1 = LazyCachedMapCollection(source: [0, 2, 4], map: { $0 * 3 })
        let s2 = LazyCachedMapCollection(source: [0, 3, 6], map: { $0 * 2 })

        // Assert: Resulting sequences are equal
        XCTAssertEqual(s1, s2)
    }

    func test_notLazy() {
        var transformationCount = 0
        let collection = LazyCachedMapCollection(source: Array(0...10)) { item -> Int in
            transformationCount += 1
            return item
        }

        // Transformed on init
        XCTAssertEqual(transformationCount, 11)

        transformationCount = 0
        _ = collection[1]
        _ = collection[5]
        XCTAssertEqual(transformationCount, 0)
    }
}

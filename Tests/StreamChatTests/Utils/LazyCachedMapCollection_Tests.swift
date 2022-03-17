//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class LazyCachedMapCollection_Tests: XCTestCase {
    func test_mapIsLazy() {
        // Arrange: Prepare sequence that records transformations
        var mapped: Set<Int> = []
        var transformationCount = 0
        let collection = LazyCachedMapCollection(source: Array(0...10)) { item -> Int in
            mapped.insert(item)
            transformationCount += 1
            return item
        }

        // Act: Request random elements
        _ = collection[1]
        _ = collection[5]

        // Act: Request second time
        _ = collection[1]
        _ = collection[5]

        // Assert: Only requested elements where transformed and only once
        XCTAssertEqual(mapped, [1, 5])
        XCTAssertEqual(transformationCount, 2)
    }

    func test_creatingCollection_doesntEvaluateSourceLazyCollection() {
        // Create source collection that is lazy and record when it's evaluated
        let source = [0, 1, 2]
        var lazyMappedEvaluatedValues: [Int] = []
        let lazyMappedSource = source.lazy.map { number -> String in
            lazyMappedEvaluatedValues.append(number)
            return String(number)
        }

        // So far no values should be evaluated
        assert(lazyMappedEvaluatedValues.isEmpty)

        // Create a new LazyCachedMapCollection
        let collection = lazyMappedSource.lazyCachedMap { $0 }

        // Assert the source collection wasn't evaluated yet
        XCTAssertTrue(lazyMappedEvaluatedValues.isEmpty)

        // Try access a single value and assert only that one is evaluated
        XCTAssertEqual(collection[0], "0")
        XCTAssertEqual(lazyMappedEvaluatedValues, [0])

        // Accessing the same value multiple times should not re-evaluate it
        _ = collection[0]
        XCTAssertEqual(lazyMappedEvaluatedValues, [0])

        // Access another value and assert only the accessed values are evaluated
        XCTAssertEqual(collection[2], "2")
        XCTAssertEqual(lazyMappedEvaluatedValues, [0, 2])
    }

    func test_equalByTransformedContent() {
        // Arrange: Prepare two lazy sequences that gives same result but have different sources and transformations
        let s1 = LazyCachedMapCollection(source: [0, 2, 4], map: { $0 * 3 })
        let s2 = LazyCachedMapCollection(source: [0, 3, 6], map: { $0 * 2 })

        // Assert: Resulting sequences are equal
        XCTAssertEqual(s1, s2)
    }
}

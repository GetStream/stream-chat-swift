//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SearchDebouncePolicy_Tests: XCTestCase {
    func test_default_usesLongerIntervalForShortQueries() {
        let policy = SearchDebouncePolicy.default

        XCTAssertEqual(policy.interval(forQueryLength: 0), 0)
        XCTAssertEqual(policy.interval(forQueryLength: 1), 0.5)
        XCTAssertEqual(policy.interval(forQueryLength: 2), 0.5)
        XCTAssertEqual(policy.interval(forQueryLength: 3), 0.3)
        XCTAssertEqual(policy.interval(forQueryLength: 10), 0.3)
    }

    func test_constant_appliesSameIntervalForAllLengths() {
        let policy = SearchDebouncePolicy.constant(0.25)

        XCTAssertEqual(policy.interval(forQueryLength: 0), 0)
        XCTAssertEqual(policy.interval(forQueryLength: 1), 0.25)
        XCTAssertEqual(policy.interval(forQueryLength: 100), 0.25)
    }

    func test_thresholds_areSortedByCharacterCount() {
        let policy = SearchDebouncePolicy(thresholds: [
            .init(maximumCharacterCount: 10, interval: 0.1),
            .init(maximumCharacterCount: 2, interval: 0.9)
        ])

        XCTAssertEqual(policy.interval(forQueryLength: 1), 0.9)
        XCTAssertEqual(policy.interval(forQueryLength: 5), 0.1)
    }

    func test_default_minimumCharacterCountIsOne() {
        XCTAssertEqual(SearchDebouncePolicy.default.minimumCharacterCount, 1)
    }

    func test_shouldPerformSearch_respectsMinimumCharacterCount() {
        let policy = SearchDebouncePolicy.constant(0.3, minimumCharacterCount: 3)

        XCTAssertTrue(policy.shouldPerformSearch(forQueryLength: 0))
        XCTAssertFalse(policy.shouldPerformSearch(forQueryLength: 1))
        XCTAssertFalse(policy.shouldPerformSearch(forQueryLength: 2))
        XCTAssertTrue(policy.shouldPerformSearch(forQueryLength: 3))
        XCTAssertTrue(policy.shouldPerformSearch(forQueryLength: 10))
    }

    func test_minimumCharacterCount_isAtLeastOne() {
        let policy = SearchDebouncePolicy.constant(0.3, minimumCharacterCount: 0)
        XCTAssertEqual(policy.minimumCharacterCount, 1)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import XCTest

final class GIFMemoryBudget_Tests: XCTestCase {
    func test_reserve_withinTheLimit_succeeds() {
        let budget = GIFMemoryBudget(limit: 100)

        XCTAssertTrue(budget.reserve(60))
        XCTAssertTrue(budget.reserve(40))
    }

    func test_reserve_overTheLimit_fails() {
        let budget = GIFMemoryBudget(limit: 100)
        XCTAssertTrue(budget.reserve(60))

        XCTAssertFalse(budget.reserve(41))
    }

    func test_release_makesTheBytesAvailableAgain() {
        let budget = GIFMemoryBudget(limit: 100)
        XCTAssertTrue(budget.reserve(100))

        budget.release(100)

        XCTAssertTrue(budget.reserve(100))
    }
}

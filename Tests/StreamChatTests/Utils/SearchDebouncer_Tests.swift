//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SearchDebouncer_Tests: XCTestCase {
    func test_schedule_withZeroInterval_executesImmediately() {
        let debouncer = SearchDebouncer(policy: .constant(0), queue: .main)
        var executed = false

        debouncer.schedule(queryLength: 1) { _ in
            executed = true
        }

        XCTAssertTrue(executed)
    }

    func test_schedule_cancelsPreviousPendingWork() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2),
            queue: .main
        )
        let expectation = expectation(description: "Only latest work executes")
        var executionCount = 0

        debouncer.schedule(queryLength: 1) { _ in
            executionCount += 1
            XCTFail("First scheduled work should be cancelled")
        }
        debouncer.schedule(queryLength: 3) { isStale in
            XCTAssertFalse(isStale())
            executionCount += 1
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(executionCount, 1)
    }

    func test_cancel_invalidatesPendingAndInFlightGenerations() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2),
            queue: .main
        )
        let expectation = expectation(description: "Cancelled work does not run")
        expectation.isInverted = true

        debouncer.schedule(queryLength: 1) { _ in
            expectation.fulfill()
        }
        debouncer.cancel()

        wait(for: [expectation], timeout: 0.4)
    }
}

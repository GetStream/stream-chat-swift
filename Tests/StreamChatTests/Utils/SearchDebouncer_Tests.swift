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

        let scheduled = debouncer.schedule(queryLength: 1) {
            executed = true
        }

        XCTAssertTrue(scheduled)
        XCTAssertTrue(executed)
    }

    func test_schedule_cancelsPreviousPendingWork() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2),
            queue: .main
        )
        let expectation = expectation(description: "Only latest work executes")
        var executionCount = 0

        debouncer.schedule(queryLength: 1) {
            executionCount += 1
            XCTFail("First scheduled work should be cancelled")
        }
        debouncer.schedule(queryLength: 3) {
            executionCount += 1
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(executionCount, 1)
    }

    func test_cancel_dropsPendingWork() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2),
            queue: .main
        )
        let expectation = expectation(description: "Cancelled work does not run")
        expectation.isInverted = true

        debouncer.schedule(queryLength: 1) {
            expectation.fulfill()
        }
        debouncer.cancel()

        wait(for: [expectation], timeout: 0.4)
    }

    func test_schedule_belowMinimumCharacterCount_skipsAndCancelsPending() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2, minimumCharacterCount: 3),
            queue: .main
        )
        let expectation = expectation(description: "Pending work is cancelled by short query")
        expectation.isInverted = true

        debouncer.schedule(queryLength: 3) {
            expectation.fulfill()
        }
        let scheduled = debouncer.schedule(queryLength: 1) {
            XCTFail("Work below the minimum character count should not run")
        }

        XCTAssertFalse(scheduled)
        wait(for: [expectation], timeout: 0.4)
    }
}

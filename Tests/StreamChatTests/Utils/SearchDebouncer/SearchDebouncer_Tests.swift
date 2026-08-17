//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SearchDebouncer_Tests: XCTestCase {
    func test_schedule_withZeroInterval_executesImmediately() {
        let debouncer = SearchDebouncer(policy: .constant(0), queue: .main)
        let executed = AllocatedUnfairLock(false)

        let scheduled = debouncer.schedule(queryLength: 1) {
            executed.withLock { $0 = true }
        }

        XCTAssertTrue(scheduled)
        XCTAssertTrue(executed.value)
    }

    func test_schedule_cancelsPreviousPendingWork() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2),
            queue: .main
        )
        let expectation = expectation(description: "Only latest work executes")
        let executionCount = AllocatedUnfairLock(0)

        debouncer.schedule(queryLength: 1) {
            executionCount.withLock { $0 += 1 }
            XCTFail("First scheduled work should be cancelled")
        }
        debouncer.schedule(queryLength: 3) {
            executionCount.withLock { $0 += 1 }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(executionCount.value, 1)
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

        wait(for: [expectation], timeout: defaultTimeout)
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
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_scheduleFilter_withSearchText_isDebouncedOnItsLength() {
        let debouncer = SearchDebouncer(
            policy: .constant(0.2, minimumCharacterCount: 3),
            queue: .main
        )
        let expectation = expectation(description: "Work below the minimum character count does not run")
        expectation.isInverted = true

        let scheduled = debouncer.schedule(filter: Filter<UserListFilterScope>.autocomplete(.name, text: "ab")) {
            expectation.fulfill()
        }

        XCTAssertFalse(scheduled)
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_scheduleFilter_withoutSearchText_executesImmediatelyAndCancelsPending() {
        let debouncer = SearchDebouncer(policy: .constant(0.2), queue: .main)
        let expectation = expectation(description: "Pending text search is cancelled")
        expectation.isInverted = true
        let executed = AllocatedUnfairLock(false)

        debouncer.schedule(filter: Filter<UserListFilterScope>.autocomplete(.name, text: "abc")) {
            expectation.fulfill()
        }
        debouncer.schedule(filter: Filter<UserListFilterScope>.equal(.id, to: .unique)) {
            executed.withLock { $0 = true }
        }

        XCTAssertTrue(executed.value)
        wait(for: [expectation], timeout: defaultTimeout)
    }
}

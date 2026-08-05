//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SearchDebouncer_Tests: XCTestCase {
    func test_schedule_withZeroInterval_executesImmediately() {
        let debouncer = SearchDebouncer(policy: .constant(0), queue: .main)
        let executed = LockedFlag()

        let scheduled = debouncer.schedule(queryLength: 1) {
            executed.set()
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
        let executionCount = LockedCounter()

        debouncer.schedule(queryLength: 1) {
            executionCount.increment()
            XCTFail("First scheduled work should be cancelled")
        }
        debouncer.schedule(queryLength: 3) {
            executionCount.increment()
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
        wait(for: [expectation], timeout: 0.4)
    }

    func test_scheduleFilter_withoutSearchText_executesImmediatelyAndCancelsPending() {
        let debouncer = SearchDebouncer(policy: .constant(0.2), queue: .main)
        let expectation = expectation(description: "Pending text search is cancelled")
        expectation.isInverted = true
        var executed = false

        debouncer.schedule(filter: Filter<UserListFilterScope>.autocomplete(.name, text: "abc")) {
            expectation.fulfill()
        }
        debouncer.schedule(filter: Filter<UserListFilterScope>.equal(.id, to: .unique)) {
            executed = true
        }

        XCTAssertTrue(executed)
        wait(for: [expectation], timeout: 0.4)
    }
}

private final class LockedFlag: @unchecked Sendable {
    private var storedValue = false
    private let lock = NSLock()

    func set() {
        lock.lock()
        storedValue = true
        lock.unlock()
    }

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storedValue
    }
}

private final class LockedCounter: @unchecked Sendable {
    private var count = 0
    private let lock = NSLock()

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}

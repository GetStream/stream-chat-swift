//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AsyncSearchDebouncer_Tests: XCTestCase {
    func test_schedule_withZeroInterval_executesImmediately() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0))
        let executed = DebouncerTestFlag()

        let result = try await debouncer.schedule(queryLength: 1) {
            await executed.set()
            return "ok"
        }

        XCTAssertEqual(result, "ok")
        let didExecute = await executed.value
        XCTAssertTrue(didExecute)
    }

    func test_schedule_cancelsPreviousPendingWork() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0.2))
        let executionCount = DebouncerTestCounter()

        async let first = debouncer.schedule(queryLength: 1) {
            await executionCount.increment()
            XCTFail("First scheduled work should be cancelled")
            return "first"
        }

        // Let the first schedule register before superseding it.
        try await Task.sleep(nanoseconds: 10_000_000)

        async let second = debouncer.schedule(queryLength: 3) {
            await executionCount.increment()
            return "second"
        }

        let firstResult = try await first
        XCTAssertNil(firstResult, "A superseded search returns nil instead of throwing")

        let secondResult = try await second
        XCTAssertEqual(secondResult, "second")
        let count = await executionCount.value
        XCTAssertEqual(count, 1)
    }

    func test_cancel_invalidatesPendingWork() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0.2))

        async let result = debouncer.schedule(queryLength: 1) {
            XCTFail("Cancelled work should not run")
            return "ok"
        }

        try await Task.sleep(nanoseconds: 10_000_000)
        await debouncer.cancel()

        let value = try await result
        XCTAssertNil(value, "A cancelled search returns nil instead of throwing")
    }

    func test_schedule_belowMinimumCharacterCount_skipsAndCancelsPending() async throws {
        let debouncer = AsyncSearchDebouncer(
            policy: .constant(0.2, minimumCharacterCount: 3)
        )

        async let first = debouncer.schedule(queryLength: 3) {
            XCTFail("Pending work should be cancelled by a short query")
            return "first"
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        let skipped = try await debouncer.schedule(queryLength: 1) {
            XCTFail("Work below the minimum character count should not run")
            return "skipped"
        }

        XCTAssertNil(skipped)
        let firstResult = try await first
        XCTAssertNil(firstResult, "A superseded search returns nil instead of throwing")
    }

    func test_scheduleFilter_withSearchText_isDebouncedOnItsLength() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0.2, minimumCharacterCount: 3))

        let skipped = try await debouncer.schedule(filter: Filter<UserListFilterScope>.autocomplete(.name, text: "ab")) {
            XCTFail("Work below the minimum character count should not run")
            return "skipped"
        }

        XCTAssertNil(skipped)
    }

    func test_scheduleFilter_withoutSearchText_runsImmediately() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(5))
        let startedAt = Date()

        let result = try await debouncer.schedule(filter: Filter<UserListFilterScope>.equal(.id, to: .unique)) {
            "result"
        }

        XCTAssertEqual("result", result)
        XCTAssertLessThan(Date().timeIntervalSince(startedAt), 1)
    }

    func test_schedule_whenCallingTaskIsCancelled_cancelsTheSearch() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0))
        let started = expectation(description: "Search operation started")
        let observedCancellation = expectation(description: "Search operation observed cancellation")

        let task = Task {
            try await debouncer.schedule(queryLength: 3) {
                started.fulfill()
                do {
                    // Long enough that the cancellation lands while the search is suspended.
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                } catch {
                    observedCancellation.fulfill()
                    throw error
                }
                XCTFail("Search should not run to completion after the caller was cancelled")
                return "finished"
            }
        }

        await fulfillment(of: [started], timeout: defaultTimeout)
        task.cancel()

        await fulfillment(of: [observedCancellation], timeout: defaultTimeout)
        do {
            _ = try await task.value
            XCTFail("Cancelled search should throw CancellationError")
        } catch is CancellationError {}
    }
}

private actor DebouncerTestFlag {
    private(set) var value = false

    func set() {
        value = true
    }
}

private actor DebouncerTestCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

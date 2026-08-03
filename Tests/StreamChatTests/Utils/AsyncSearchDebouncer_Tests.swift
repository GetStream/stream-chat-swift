//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AsyncSearchDebouncer_Tests: XCTestCase {
    func test_schedule_withZeroInterval_executesImmediately() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0))
        var executed = false

        let result = try await debouncer.schedule(queryLength: 1) {
            executed = true
            return "ok"
        }

        XCTAssertEqual(result, "ok")
        XCTAssertTrue(executed)
    }

    func test_schedule_cancelsPreviousPendingWork() async throws {
        let debouncer = AsyncSearchDebouncer(policy: .constant(0.2))
        var executionCount = 0

        async let first = debouncer.schedule(queryLength: 1) {
            executionCount += 1
            XCTFail("First scheduled work should be cancelled")
            return "first"
        }

        // Let the first schedule register before superseding it.
        try await Task.sleep(nanoseconds: 10_000_000)

        async let second = debouncer.schedule(queryLength: 3) {
            executionCount += 1
            return "second"
        }

        let firstResult = try await first
        XCTAssertNil(firstResult, "A superseded search returns nil instead of throwing")

        let secondResult = try await second
        XCTAssertEqual(secondResult, "second")
        XCTAssertEqual(executionCount, 1)
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

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

        do {
            _ = try await first
            XCTFail("Superseded search should throw CancellationError")
        } catch is CancellationError {}

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
        debouncer.cancel()

        do {
            _ = try await result
            XCTFail("Cancelled search should throw CancellationError")
        } catch is CancellationError {}
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
        do {
            _ = try await first
            XCTFail("Superseded search should throw CancellationError")
        } catch is CancellationError {}
    }
}

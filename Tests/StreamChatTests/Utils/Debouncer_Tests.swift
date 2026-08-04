//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Debouncer_Tests: XCTestCase {
    private lazy var queue: DispatchQueue! = .main
    private lazy var debouncer: Debouncer! = .init(0.5, queue: queue)

    override func tearDown() {
        queue = nil
        debouncer = nil
        super.tearDown()
    }

    // MARK: - execute

    func test_execute_willExecuteBlockOnProvidedQueue() {
        let expectation = XCTestExpectation(description: "Debouncer executes block on provided queue")

        // Execute the block and expect it to be executed on the provided queue
        debouncer.execute {
            dispatchPrecondition(condition: .onQueue(self.queue))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_execute_willExecuteBlockAfterInterval() {
        let expectation = XCTestExpectation(description: "Debouncer executes block after interval")
        var debouncer = Debouncer(0.5)

        /// Execute the block twice with a 0.5 second interval, but expect it to only execute once
        /// after 0.5 seconds
        debouncer.execute {
            XCTFail()
        }
        debouncer.execute {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
    }

    // MARK: - invalidate

    func test_invalidate_willCancelPendingBlock() {
        let expectation = XCTestExpectation(description: "Debouncer cancels pending block")
        var debouncer = Debouncer(0.5)

        // Execute the block, then cancel it, then wait for the 0.5 second interval to ensure it doesn't execute
        debouncer.execute {
            XCTFail("Block should have been cancelled")
        }
        debouncer.invalidate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
    }
}

final class Debouncer_SearchPolicy_Tests: XCTestCase {
    func test_execute_withZeroIntervalPolicy_runsImmediately() {
        var debouncer = Debouncer(policy: .constant(0), queue: .main)
        var executed = false

        let scheduled = debouncer.execute(queryLength: 3) { executed = true }

        XCTAssertTrue(scheduled)
        XCTAssertTrue(executed)
    }

    func test_execute_usesTheIntervalForTheQueryLength() {
        var debouncer = Debouncer(policy: .default, queue: .main)
        let expectation = expectation(description: "Short query waits the longer interval")
        var executed = false

        debouncer.execute(queryLength: 1) { executed = true }

        // The default policy waits 500ms for a single character.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertFalse(executed)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            XCTAssertTrue(executed)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_execute_cancelsThePreviousPendingWork() {
        var debouncer = Debouncer(policy: .constant(0.2), queue: .main)
        let expectation = expectation(description: "Only the latest work runs")
        var executionCount = 0

        debouncer.execute(queryLength: 1) {
            XCTFail("The superseded work should not run")
            executionCount += 1
        }
        debouncer.execute(queryLength: 3) {
            executionCount += 1
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(1, executionCount)
    }

    func test_execute_belowMinimumCharacterCount_skipsAndCancelsPending() {
        var debouncer = Debouncer(policy: .constant(0.2, minimumCharacterCount: 3), queue: .main)
        let expectation = expectation(description: "Pending work is cancelled by a short query")
        expectation.isInverted = true

        debouncer.execute(queryLength: 3) { expectation.fulfill() }
        let scheduled = debouncer.execute(queryLength: 1) {
            XCTFail("Work below the minimum character count should not run")
        }

        XCTAssertFalse(scheduled)
        wait(for: [expectation], timeout: 0.4)
    }
}

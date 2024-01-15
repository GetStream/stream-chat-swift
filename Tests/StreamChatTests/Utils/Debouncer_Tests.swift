//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

        wait(for: [expectation], timeout: 1.0)
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

        wait(for: [expectation], timeout: 1.0)
    }
}

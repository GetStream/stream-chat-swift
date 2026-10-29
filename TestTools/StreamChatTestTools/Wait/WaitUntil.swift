//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    public func waitUntil(timeout: TimeInterval = 0.5, _ action: (_ done: @escaping () -> Void) -> Void) {
        let expectation = XCTestExpectation(description: "Action completed")
        action {
            if Thread.isMainThread {
                expectation.fulfill()
            } else {
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: timeout)
    }

    /// Waits until the condition is true, checking it on the main run loop.
    public func wait(
        until condition: @escaping () -> Bool,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Condition is true")
        // The timer fires on the main run loop, the same thread the condition comes from.
        nonisolated(unsafe) let condition = condition
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            guard condition() else { return }
            timer.invalidate()
            expectation.fulfill()
        }
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        timer.invalidate()
        XCTAssertEqual(result, .completed, "The condition did not become true", file: file, line: line)
    }

    /// Checks that the condition stays true for the whole timeout, on the main run loop.
    public func waitWhile(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = defaultTimeoutForInversedExpecations,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Condition becomes false")
        expectation.isInverted = true
        nonisolated(unsafe) let condition = condition
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            guard !condition() else { return }
            timer.invalidate()
            expectation.fulfill()
        }
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        timer.invalidate()
        XCTAssertEqual(result, .completed, "The condition became false", file: file, line: line)
    }
}

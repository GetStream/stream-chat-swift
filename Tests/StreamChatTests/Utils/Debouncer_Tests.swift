//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI
import XCTest

final class DebouncerTests: XCTestCase {
    // Test the debounce method to ensure that the handler
    // closure is executed only after the debounce interval
    // has elapsed.
    func testDebounce() {
        // Create an expectation for the handler closure.
        let expectation = XCTestExpectation(
            description: "Handler closure is executed."
        )

        // Create a Debouncer instance with a debounce interval of 1 second
        let debouncer = Debouncer(interval: 1.0)

        // Call the debounce method twice with a 0.5 second delay between calls.
        debouncer.debounce { expectation.fulfill() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            debouncer.debounce { expectation.fulfill() }
        }

        // Wait for the expectation to be fulfilled after the debounce interval
        // has elapsed.
        wait(for: [expectation], timeout: 2.0)
    }

    // Test the cancel method to ensure that any pending debounce
    // calls are cancelled.
    func testCancel() {
        // Create an expectation for the handler closure.
        let expectation = XCTestExpectation(
            description: "Handler closure is not executed."
        )
        expectation.isInverted = true

        // Create a Debouncer instance with a debounce interval of 1 second
        let debouncer = Debouncer(interval: 1.0)

        // Call the debounce method and immediately cancel the pending
        // debounce call.
        debouncer.debounce { expectation.fulfill() }
        debouncer.cancel()

        // Wait for the expectation to be fulfilled.
        wait(for: [expectation], timeout: 1.5)
    }

    // Test that calling the debounce method multiple times within
    // the debounce interval only executes the handler closure once.
    func testMultipleCalls() {
        // Create an expectation for the handler closure.
        let expectation = XCTestExpectation(
            description: "Handler closure is executed once."
        )
        expectation.expectedFulfillmentCount = 1

        // Create a Debouncer instance with a debounce interval of 1 second
        let debouncer = Debouncer(interval: 1.0)

        // Call the debounce method multiple times with a 0.5 second delay
        // between calls.
        debouncer.debounce { expectation.fulfill() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            debouncer.debounce { expectation.fulfill() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            debouncer.debounce { expectation.fulfill() }
        }

        // Wait for the expectation to be fulfilled after the debounce
        // interval has elapsed.
        wait(for: [expectation], timeout: 3)
    }
}

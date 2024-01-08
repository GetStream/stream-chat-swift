//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Batch_Tests: XCTestCase {
    var time: VirtualTime { VirtualTimeTimer.time }

    override func setUp() {
        super.setUp()

        VirtualTimeTimer.time = .init()
    }

    override func tearDown() {
        VirtualTimeTimer.invalidate()

        super.tearDown()
    }

    func test_append() {
        // Create batcher for test events and keep track of handler calls
        var handlerCalls = [[TestEvent]]()
        let batcher = Batcher<TestEvent>(period: 10, timerType: VirtualTimeTimer.self) { events, _ in
            handlerCalls.append(events)
        }

        // Prepare some batches of events
        let event1 = TestEvent()
        let event2 = TestEvent()

        // Add 1st event to batch
        batcher.append(event1)

        // Wait a bit less then period
        time.run(numberOfSeconds: 1)
        // Assert current batch contains expected values
        XCTAssertEqual(batcher.currentBatch, [event1])
        // Assert handler is not called yet
        XCTAssertEqual(handlerCalls, [])

        // Add 2nd event to batch
        batcher.append(event2)

        // Wait a bit less then period
        time.run(numberOfSeconds: 1)
        // Assert current batch contains expected values
        XCTAssertEqual(batcher.currentBatch, [event1, event2])
        // Assert handler is not called yet
        XCTAssertEqual(handlerCalls, [])

        // Wait another bit so batch period has passed
        time.run(numberOfSeconds: 10)
        // Assert handler is called a single time with batched events
        XCTAssertEqual(handlerCalls, [[event1, event2]])
        // Assert current batch is empty
        XCTAssertTrue(batcher.currentBatch.isEmpty)

        // Clear handler
        handlerCalls.removeAll()

        // Wait another bit so another batch period has passed
        time.run(numberOfSeconds: 20)

        // Assert handler is not fired again
        XCTAssertTrue(handlerCalls.isEmpty)
    }

    func test_processImmidiately() {
        // Create batcher with long period and keep track of handler calls
        var handlerCalls = [[TestEvent]]()
        var handlerCompletion: (() -> Void)?
        let batcher = Batcher<TestEvent>(period: 20, timerType: VirtualTimeTimer.self) { events, completion in
            handlerCalls.append(events)
            handlerCompletion = completion
        }

        // Prepare the event
        let event = TestEvent()

        // Append the event
        batcher.append(event)

        // Ask to process immidiately
        let expectation = expectation(description: "`processImmediately` completion")
        batcher.processImmediately {
            expectation.fulfill()
        }

        // Wait for a small bit of time much less then a period
        time.run(numberOfSeconds: 0.1)

        // Assert handler is called sooner
        XCTAssertEqual(handlerCalls, [[event]])

        // Complete batch processing
        handlerCompletion?()

        // Assert current batch is empty
        XCTAssertEqual(batcher.currentBatch, [])
        wait(for: [expectation], timeout: defaultTimeout)
    }
}

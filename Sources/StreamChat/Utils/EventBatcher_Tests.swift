//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Batch_Tests: StressTestCase {
    func test_processImmidiately() {
        // Create batcher with long period and keep track of handler calls
        var handlerCalls = [[TestEvent]]()
        let batcher = Batcher<TestEvent>(period: 20) { events in
            handlerCalls.append(events)
        }
        
        // Prepare the event
        let event = TestEvent()
        
        // Append the event
        batcher.append(event)
        
        // Ask to process immidiately
        batcher.processImmidiately()
        
        // Wait for a small bit of time much less then a period
        wait(0.1)
        
        // Assert handler is called sooner
        XCTAssertEqual(handlerCalls, [[event]])
        
        // Assert current batch is empty
        XCTAssertEqual(batcher.currentBatch, [])
    }
    
    func test_append() {
        // Create batcher for test events and keep track of handler calls
        var handlerCalls = [[TestEvent]]()
        let batcher = Batcher<TestEvent>(period: 0.2) { events in
            handlerCalls.append(events)
        }

        // Prepare some batches of events
        let event1 = TestEvent()
        let event2 = TestEvent()
        
        // Add 1st event to batch
        batcher.append(event1)
        
        // Wait a bit less then period
        wait(0.05)
        // Assert current batch contains expected values
        XCTAssertEqual(batcher.currentBatch, [event1])
        // Assert handler is not called yet
        XCTAssertEqual(handlerCalls, [])
        
        // Add 2nd event to batch
        batcher.append(event2)
        
        // Wait a bit less then period
        wait(0.05)
        // Assert current batch contains expected values
        XCTAssertEqual(batcher.currentBatch, [event1, event2])
        // Assert handler is not called yet
        XCTAssertEqual(handlerCalls, [])
        
        // Wait another bit so batch period has passed
        wait(0.2)
        // Assert handler is called a single time with batched events
        XCTAssertEqual(handlerCalls, [[event1, event2]])
        // Assert current batch is empty
        XCTAssertTrue(batcher.currentBatch.isEmpty)
        
        // Clear handler
        handlerCalls.removeAll()
        
        // Wait another bit so another batch period has passed
        wait(0.5)
        
        // Assert handler is not fired again
        XCTAssertTrue(handlerCalls.isEmpty)
    }
}

private extension Batch_Tests {
    func wait(_ time: TimeInterval) {
        let start = Date()
        AssertAsync.willBeTrue(Date().timeIntervalSince(start) >= time)
    }
}

// MARK: - Helpers

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}

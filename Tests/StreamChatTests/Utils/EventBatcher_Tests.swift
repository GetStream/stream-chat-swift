//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Batch_Tests: XCTestCase {
    var time: VirtualTime { VirtualTimeTimer.time }
    
    override func setUp() {
        super.setUp()
        
        VirtualTimeTimer.time = .init()
    }
    
    override func tearDown() {
        VirtualTimeTimer.time = nil
        
        super.tearDown()
    }
    
    func test_append() {
        // Create batcher for test events and keep track of handler calls
        var handlerCalls = [[TestEvent]]()
        let batcher = Batcher<TestEvent>(period: 10, timerType: VirtualTimeTimer.self) { events in
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
        let batcher = Batcher<TestEvent>(period: 20, timerType: VirtualTimeTimer.self) { events in
            handlerCalls.append(events)
        }
        
        // Prepare the event
        let event = TestEvent()
        
        // Append the event
        batcher.append(event)
        
        // Ask to process immidiately
        batcher.processImmediately()
        
        // Wait for a small bit of time much less then a period
        time.run(numberOfSeconds: 0.1)
        
        // Assert handler is called sooner
        XCTAssertEqual(handlerCalls, [[event]])
        
        // Assert current batch is empty
        XCTAssertEqual(batcher.currentBatch, [])
    }
}

// MARK: - Helpers

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}

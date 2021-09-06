//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventNotificationCenter_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_init_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddlewareMock] = [
            .init(),
            .init(),
            .init()
        ]
        
        // Create notification center with middlewares
        let center = EventNotificationCenter(database: database)
        middlewares.forEach(center.add)

        // Assert middlewares are assigned correctly
        let centerMiddlewares = center.middlewares as! [EventMiddlewareMock]
        XCTAssertEqual(middlewares.count, centerMiddlewares.count)
        zip(middlewares, centerMiddlewares).forEach {
            XCTAssertTrue($0.0 === $0.1)
        }
    }
    
    func test_addMiddleware_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddlewareMock] = [
            .init(),
            .init(),
            .init()
        ]
        
        // Create notification center without any middlewares
        let center = EventNotificationCenter(database: database)
        
        // Add middlewares via `add` method
        middlewares.forEach(center.add)
        
        // Assert middlewares are assigned correctly
        let centerMiddlewares = center.middlewares as! [EventMiddlewareMock]
        XCTAssertEqual(middlewares.count, centerMiddlewares.count)
        zip(middlewares, centerMiddlewares).forEach {
            XCTAssertTrue($0.0 === $0.1)
        }
    }
    
    func test_eventIsNotPublished_ifSomeMiddlewareDoesNotForwardEvent() {
        let consumingMiddleware = EventMiddlewareMock { _, _ in nil }

        // Create a notification center with blocking middleware
        let center = EventNotificationCenter(database: database)
        center.add(middleware: consumingMiddleware)

        // Create event logger to check published events
        let eventLogger = EventLogger(center)
        
        // Simulate incoming event
        center.process(TestEvent())
        
        // Assert event is published as it is
        AssertAsync.staysTrue(eventLogger.equatableEvents.isEmpty)
    }
    
    func test_eventIsPublishedAsItIs_ifThereAreNoMiddlewares() {
        // Create a notification center without any middlewares
        let center = EventNotificationCenter(database: database)
        
        // Create event logger to check published events
        let eventLogger = EventLogger(center)
        
        // Simulate incoming event
        let event = TestEvent()
        center.process(event)
        
        // Assert event is published as it is
        AssertAsync.willBeEqual(eventLogger.events as? [TestEvent], [event])
    }
    
    func test_healthCheckEventIsNotPublished() {
        // Create a notification center without any middlewares
        let center = EventNotificationCenter(database: database)
        
        // Create event logger to check published events
        let eventLogger = EventLogger(center)
        
        // Simulate incoming `HealthCheckEvent` event
        let event = HealthCheckEvent(connectionId: .unique)
        center.process(event)
        
        // Assert `HealthCheckEvent` is not published
        AssertAsync.staysTrue(eventLogger.events.isEmpty)
    }
    
    func test_eventsAreProcessed_fromWithinTheWriteClosure() {
        // Create a notification center without any middlewares
        let center = EventNotificationCenter(database: database)
        
        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Create incoming event
        let event = TestEvent()

        var usedSession: DatabaseSession?
        
        // Inject spy middleware
        center.add(middleware: EventMiddlewareMock(closure: { event, session in
            usedSession = session
            XCTAssertTrue(self.database.isWriteSessionInProgress)
            return event
        }))
        
        // Submit event to processing
        center.process(event)
        
        // Assert the event is processed and the correct session is used
        AssertAsync {
            Assert.willBeEqual(usedSession as? NSManagedObjectContext, self.database.writableContext)
            Assert.willBeEqual(eventLogger.events as? [TestEvent], [event])
        }
    }
    
    func test_eventsAreBatched() {
        // Create a notification center with just a forwarding middleware
        let center = EventNotificationCenter(database: database)

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Prepare test events
        let testEvents = [TestEvent(), TestEvent(), TestEvent(), TestEvent()]
        
        // Note: The most correct approach would be to mock the timer and mock this whole thing. However
        // it's just a couple of milliseconds and it safes us a lot of complexity, so I decided to do it
        // directly like this. Let's see it bites back 🤞.
        center.eventBatchPeriod = 0.2

        // Assert no write sessions exist yet
        XCTAssertEqual(database.writeSessionCounter, 0)
        
        // Submit some events
        center.process(testEvents[0])
        center.process(testEvents[1])
        
        // Wait a bit and assert no write sessions happen
        wait(0.1)
        XCTAssertEqual(database.writeSessionCounter, 0)

        // Wait another bit and assert the events were processed in a single session
        wait(0.3)
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertEqual(eventLogger.events as! [TestEvent], Array(testEvents[0...1]))
        
        // Submit more events
        center.process(testEvents[2])
        center.process(testEvents[3])
        
        // Wait a bit and assert no additional write sessions happen
        wait(0.1)
        XCTAssertEqual(database.writeSessionCounter, 1)
        
        // Wait another bit and assert the events were processed in another session
        wait(0.3)
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(eventLogger.events as! [TestEvent], testEvents)
    }
    
    func test_addToCurrentBatchAndProcessImmediately() {
        // Create a notification center with just a forwarding middleware
        let center = EventNotificationCenter(database: database)
        
        // Create event logger to check published events
        let eventLogger = EventLogger(center)
        
        // Schedule some events
        let batchedEvents = [TestEvent(), TestEvent(), TestEvent(), TestEvent()]
        for event in batchedEvents {
            center.process(event)
        }
        
        // Simulate event that should be processed immediately and catch the completion
        let targetEvent = TestEvent()
        var completionCalled = false
        center.addToCurrentBatchAndProcessImmediately([targetEvent]) {
            completionCalled = true
        }
        // Assert pending events are cleared immediately
        XCTAssertTrue(center.pendingEvents.isEmpty)
        // Assert database session opening is initiated.
        XCTAssertTrue(database.write_called)

        // Wait completion to be called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert target event is included into the current batch and processing order is correct.
        XCTAssertEqual(eventLogger.events as! [TestEvent], batchedEvents + [targetEvent])
    }
}

private extension EventNotificationCenter_Tests {
    func wait(_ time: TimeInterval) {
        let start = Date()
        AssertAsync.willBeTrue(Date().timeIntervalSince(start) >= time)
    }
}

// MARK: - Helpers

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}

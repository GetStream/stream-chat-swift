//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

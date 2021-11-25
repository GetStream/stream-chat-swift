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
    
    func test_process_whenShouldPostEventsIsTrue_eventsArePosted() {
        // Create a notification center with just a forwarding middleware
        let center = EventNotificationCenter(database: database)

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Simulate incoming events
        let events = [TestEvent(), TestEvent(), TestEvent(), TestEvent()]

        // Feed events that should be posted and catch the completion
        var completionCalled = false
        center.process(events, post: true) {
            completionCalled = true
        }
        
        // Wait completion to be called
        AssertAsync.willBeTrue(completionCalled)

        // Assert events are posted.
        XCTAssertEqual(eventLogger.events as! [TestEvent], events)
    }

    func test_process_whenShouldPostEventsIsFalse_eventsAreNotPosted() {
        // Create a notification center with just a forwarding middleware
        let center = EventNotificationCenter(database: database)

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Simulate incoming events
        let events = [TestEvent(), TestEvent(), TestEvent(), TestEvent()]

        // Feed events that should not be posted and catch the completion
        var completionCalled = false
        center.process(events, post: false) {
            completionCalled = true
        }
        
        // Wait completion to be called
        AssertAsync.willBeTrue(completionCalled)

        // Assert events are not posted.
        XCTAssertTrue(eventLogger.events.isEmpty)
    }
}

// MARK: - Helpers

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}

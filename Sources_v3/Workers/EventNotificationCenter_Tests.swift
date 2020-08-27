//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class EventNotificationCenter_Tests: XCTestCase {
    func test_init_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddlewareMock] = [
            .init(),
            .init(),
            .init()
        ]
        
        // Create notication center with middlewares
        let center = EventNotificationCenter(middlewares: middlewares)

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
        
        // Create notication center without any middlewares
        let center = EventNotificationCenter()
        
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
        // Create notication center with blocking middleware
        let center = EventNotificationCenter(middlewares: [
            EventMiddlewareMock { $1(nil) }
        ])

        // Create event logger to check published events
        let eventLogger = EventLogger(center)
        
        // Simulate incoming event
        center.process(TestEvent())
        
        // Assert event is published as it is
        AssertAsync.willBeTrue(eventLogger.equatableEvents.isEmpty)
    }
    
    func test_eventIsPublishedAsItIs_ifThereAreNoMiddlewares() {
        // Create notication center without any middlewares
        let center = EventNotificationCenter()
        
        // Create event logger to check published events
        let eventLogger = EventLogger(center)
        
        // Simulate incoming event
        let event = TestEvent()
        center.process(event)
        
        // Assert event is published as it is
        AssertAsync.willBeEqual(eventLogger.events as? [TestEvent], [event])
    }
}

// MARK: - Helpers

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventNotificationCenter_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_init_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddleware_Mock] = [
            .init(),
            .init(),
            .init()
        ]

        // Create notification center with middlewares
        let center = EventNotificationCenter(database: database)
        middlewares.forEach(center.add)

        // Assert middlewares are assigned correctly
        let centerMiddlewares = center.middlewares as! [EventMiddleware_Mock]
        XCTAssertEqual(middlewares.count, centerMiddlewares.count)
        zip(middlewares, centerMiddlewares).forEach {
            XCTAssertTrue($0.0 === $0.1)
        }
    }

    func test_addMiddleware_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddleware_Mock] = [
            .init(),
            .init(),
            .init()
        ]

        // Create notification center without any middlewares
        let center = EventNotificationCenter(database: database)

        // Add middlewares via `add` method
        middlewares.forEach(center.add)

        // Assert middlewares are assigned correctly
        let centerMiddlewares = center.middlewares as! [EventMiddleware_Mock]
        XCTAssertEqual(middlewares.count, centerMiddlewares.count)
        zip(middlewares, centerMiddlewares).forEach {
            XCTAssertTrue($0.0 === $0.1)
        }
    }

    func test_eventIsNotPublished_ifSomeMiddlewareDoesNotForwardEvent() {
        let consumingMiddleware = EventMiddleware_Mock { _, _ in nil }

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
        center.add(middleware: EventMiddleware_Mock(closure: { event, session in
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
        center.process(events, postNotifications: true) {
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
        center.process(events, postNotifications: false) {
            completionCalled = true
        }

        // Wait completion to be called
        AssertAsync.willBeTrue(completionCalled)

        // Assert events are not posted.
        XCTAssertTrue(eventLogger.events.isEmpty)
    }

    func test_process_postsEventsOnPostingQueue() {
        // Create notification center
        let center = EventNotificationCenter(database: database)

        // Assign mock events posting queue
        let mockQueueUUID = UUID()
        let mockQueue = DispatchQueue.testQueue(withId: mockQueueUUID)
        center.eventPostingQueue = mockQueue

        // Create test event
        let testEvent = TestEvent()

        // Setup event observer
        var observerTriggered = false

        let observer = center.addObserver(
            forName: .NewEventReceived,
            object: nil,
            queue: nil
        ) { notification in
            // Assert notification contains test event
            XCTAssertEqual(notification.event as? TestEvent, testEvent)
            // Assert notificaion is posted on correct queue
            XCTAssertTrue(DispatchQueue.isTestQueue(withId: mockQueueUUID))

            observerTriggered = true
        }

        // Process test event and post when processing is completed
        center.process([testEvent], postNotifications: true)

        // Wait for observer to be called
        AssertAsync.willBeTrue(observerTriggered)

        // Remove observer
        center.removeObserver(observer)
    }

    func test_process_whenOriginalEventIsSwapped_newEventIsProcessedFurther() {
        // Create incoming event
        let originalEvent = TestEvent()

        // Create event that will be returned instead of incoming event
        let outputEvent = TestEvent()

        // Create a notification center
        let center = EventNotificationCenter(database: database)

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Add event swapping middleware
        center.add(middleware: EventMiddleware_Mock { event, session in
            // Assert expected event is received
            XCTAssertEqual(event as? TestEvent, originalEvent)

            // Assert expected database session is received
            XCTAssertEqual(session as? NSManagedObjectContext, self.database.writableContext)

            // Simulate event swapping
            return outputEvent
        })

        // Start processing of original event
        center.process(originalEvent, postNotification: true)

        // Assert event returned from middleware is posted
        AssertAsync.willBeEqual(
            eventLogger.events.compactMap { $0 as? TestEvent },
            [outputEvent]
        )
    }

    // Performance tests

    func test_measure_processMultipleNewMessageEvents() throws {
        let existingPayloads: [MessagePayload] = (0...200).map { _ in
            MessagePayload.dummy(messageId: .unique, authorUserId: .unique)
        }
        let channelId = ChannelId.unique

        waitUntil(timeout: 100) { done in
            database.write({ session in
                try session.saveChannel(payload: ChannelPayload.dummy(channel: .dummy(cid: channelId)))
                try existingPayloads.forEach {
                    try session.saveMessage(payload: $0, for: channelId, syncOwnReactions: false, cache: nil)
                }
            }, completion: { _ in done() })
        }

        // Check all messages were created
        XCTAssertEqual(database.viewContext.channel(cid: channelId)?.messages.count, existingPayloads.count)

        let events: [MessageNewEventDTO] = try existingPayloads.map { message -> MessageNewEventDTO in
            let payload = EventPayload(eventType: .messageNew, cid: channelId, user: UserPayload.dummy(userId: .unique), message: message, createdAt: Date())
            return try MessageNewEventDTO(from: payload)
        }

        // Create a notification center
        let center = EventNotificationCenter(database: database)

        measure {
            center.process(events)
        }
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class EventDataProcessorMiddleware_Tests: XCTestCase {
    var middleware: EventDataProcessorMiddleware!
    fileprivate var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
        middleware = EventDataProcessorMiddleware()
    }
    
    override func tearDown() {
        middleware = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_eventWithPayload_isSavedToDB() throws {
        // Prepare an Event with a payload with channel data
        struct TestEvent: Event, EventDTO {
            let payload: EventPayload
        }
        
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)
        
        let eventPayload = EventPayload(
            eventType: .notificationAddedToChannel,
            connectionId: .unique,
            cid: channelPayload.channel.cid,
            channel: channelPayload.channel
        )
        
        let testEvent = TestEvent(payload: eventPayload)
        
        // Let the middleware handle the event
        let outputEvent = middleware.handle(event: testEvent, session: database.viewContext)
        
        // Assert the channel data is saved and the event is forwarded
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)!.asModel()
        }
        XCTAssertEqual(loadedChannel?.cid, channelId)
        XCTAssertEqual(outputEvent?.asEquatable, testEvent.asEquatable)
    }
    
    func test_eventWithInvalidPayload_isNotForwarded() throws {
        // Prepare an Event with an invalid payload data
        struct TestEvent: Event, EventDTO {
            let payload: EventPayload
        }
        
        // Create dummy event payload
        let eventPayload = EventPayload(eventType: .userUpdated, user: .dummy(userId: .unique))
        let testEvent = TestEvent(payload: eventPayload)
        
        // Simulate the DB fails to save the payload
        let session = DatabaseSessionMock(underlyingSession: database.viewContext)
        session.errorToReturn = TestError()
        
        // Let the middleware handle the event
        let outputEvent = middleware.handle(event: testEvent, session: session)

        // Assert the event is not forwarded
        XCTAssertNil(outputEvent)
    }
    
    func test_eventWithoutPayload_isForwarded() throws {
        // Prepare an Event without a payload
        struct TestEvent: Event {}
        
        let testEvent = TestEvent()
        
        // Let the middleware handle the event
        let outputEvent = middleware.handle(event: testEvent, session: database.viewContext)

        // Assert the event is forwarded
        XCTAssertEqual(outputEvent?.asEquatable, testEvent.asEquatable)
    }
}

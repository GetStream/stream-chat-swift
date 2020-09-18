//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class EventDataProcessorMiddleware_Tests: XCTestCase {
    var middleware: EventDataProcessorMiddleware<DefaultExtraData>!
    fileprivate var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainerMock(kind: .inMemory)
        middleware = EventDataProcessorMiddleware(database: database)
    }
    
    func test_eventWithPayload_isSavedToDB() throws {
        // Prepare an Event with a payload with channel data
        struct TestEvent: Event, EventWithPayload {
            let payload: Any
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
        let completion = try await { middleware.handle(event: testEvent, completion: $0) }
        
        // Assert the channel data is saved and the event is forwarded
        var loadedChannel: _ChatChannel<DefaultExtraData>? {
            database.viewContext.channel(cid: channelId)!.asModel()
        }
        XCTAssertEqual(loadedChannel?.cid, channelId)
        XCTAssertEqual(completion?.asEquatable, testEvent.asEquatable)
    }
    
    func test_eventWithInvalidPayload_isNotForwarded() throws {
        // Prepare an Event with an invalid payload data
        struct TestEvent: Event, EventWithPayload {
            let payload: Any
        }
        
        // This is not really used, we just need to have something to create the event with
        let somePayload = EventPayload<DefaultExtraData>(eventType: .healthCheck)
        
        let testEvent = TestEvent(payload: somePayload)
        
        // Simulate the DB fails to save the payload
        database.write_errorResponse = TestError()
        
        // Let the middleware handle the event
        let completion = try await { middleware.handle(event: testEvent, completion: $0) }
        
        // Assert the event is not forwarded
        XCTAssertNil(completion)
    }
    
    func test_eventWithoutPayload_isForwarded() throws {
        // Prepare an Event without a payload
        struct TestEvent: Event {}
        
        let testEvent = TestEvent()
        
        // Let the middleware handle the event
        let completion = try await { middleware.handle(event: testEvent, completion: $0) }
        
        // Assert the event is forwarded
        XCTAssertEqual(completion?.asEquatable, testEvent.asEquatable)
    }
}

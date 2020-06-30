//
// EventDataProcessorMiddleware_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class EventDataProcessorMiddlewaree_Tests: XCTestCase {
    var middleware: EventDataProcessorMiddleware<DefaultDataTypes>!
    fileprivate var database: TestDatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! TestDatabaseContainer(kind: .inMemory)
        middleware = EventDataProcessorMiddleware(database: database)
    }
    
    func test_eventWithPayload_isSavedToDB() throws {
        // Prepare an Event with a payload with channel data
        struct TestEvent: Event, EventWithPayload {
            static var eventRawType: String { "test event with payload" }
            let payload: Any
        }
        
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)
        let eventPayload = EventPayload(eventType: "test_event", connectionId: .unique, channel: channelPayload.channel,
                                        currentUser: nil, cid: channelPayload.channel.cid)
        
        let testEvent = TestEvent(payload: eventPayload)
        
        // Let the middleware handle the event
        let completion = try await { middleware.handle(event: testEvent, completion: $0) }
        
        // Assert the channel data is saved and the event is forwarded
        var loadedChannel: ChannelModel<DefaultDataTypes>? {
            database.viewContext.loadChannel(cid: channelId)
        }
        XCTAssertEqual(loadedChannel?.cid, channelId)
        XCTAssertEqual(completion?.asEquatable, testEvent.asEquatable)
    }
    
    func test_eventWithInvalidPayload_isNotForwarded() throws {
        // Prepare an Event with an invalid payload data
        struct TestEvent: Event, EventWithPayload {
            static var eventRawType: String { "test event with payload" }
            let payload: Any
        }
        
        // This is not really used, we just need to have something to create the event with
        let somePayload = EventPayload<DefaultDataTypes>(eventType: "test_event", connectionId: nil, channel: nil,
                                                         currentUser: nil, cid: nil)
        
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
        struct TestEvent: Event {
            static var eventRawType: String { "test event without payload" }
        }
        
        let testEvent = TestEvent()
        
        // Let the middleware handle the event
        let completion = try await { middleware.handle(event: testEvent, completion: $0) }
        
        // Assert the event is forwarded
        XCTAssertEqual(completion?.asEquatable, testEvent.asEquatable)
    }
}

/// A testable subclass of DatabaseContainer allowing response simulation.
private class TestDatabaseContainer: DatabaseContainer {
    /// If set, the `write` completion block is called with this value.
    var write_errorResponse: Error?
    
    override func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        if let error = write_errorResponse {
            super.write(actions, completion: { _ in })
            completion(error)
        } else {
            super.write(actions, completion: completion)
        }
    }
}

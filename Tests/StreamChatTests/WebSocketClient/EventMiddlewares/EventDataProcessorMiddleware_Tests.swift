//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventDataProcessorMiddleware_Tests: XCTestCase {
    var middleware: EventDataProcessorMiddleware!
    fileprivate var database: DatabaseContainer_Spy!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        middleware = EventDataProcessorMiddleware()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
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
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }
        XCTAssertEqual(loadedChannel?.cid, channelId)
        XCTAssertEqual(outputEvent?.asEquatable, testEvent.asEquatable)
    }
    
    func test_middleware_handlesReactionDeletedEvent() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: messageId,
            user: UserPayload.dummy(userId: .unique)
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
                for: cid, syncOwnReactions: true
            )
        }

        var message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )

        // pre-condition check
        XCTAssertFalse(message.latestReactions.isEmpty)

        let eventPayload: EventPayload = .init(
            eventType: .reactionDeleted,
            cid: cid,
            user: reactionPayload.user,
            message: .dummy(
                messageId: messageId,
                authorUserId: reactionPayload.user.id
            ),
            reaction: reactionPayload,
            createdAt: .unique
        )
        
        // Simulate `ReactionDeletedEvent` event.
        let event = try ReactionDeletedEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the message.
        message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )
        
        XCTAssertTrue(forwardedEvent is ReactionDeletedEventDTO)
        XCTAssertTrue(message.latestReactions.isEmpty)
    }

    func test_middleware_handlesReactionUpdated() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let messagePayload: MessagePayload = .dummy(messageId: messageId, authorUserId: .unique)
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil)
            try session.saveMessage(payload: messagePayload, for: cid, syncOwnReactions: true)
        }

        let user = UserPayload.dummy(userId: .unique)

        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: messageId,
            user: user
        )
        
        // Create event payload.
        let eventPayload: EventPayload = .init(
            eventType: .reactionUpdated,
            cid: cid,
            user: user,
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
            reaction: reactionPayload,
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try ReactionUpdatedEventDTO(from: eventPayload)

        // Simulate `ReactionUpdatedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the message.
        let message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )
        
        // Load the reaction.
        let reaction = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: reactionPayload.messageId,
                userId: reactionPayload.user.id,
                type: reactionPayload.type
            )?.asModel()
        )

        XCTAssertTrue(forwardedEvent is ReactionUpdatedEventDTO)
        try XCTAssertEqual(message.asModel().latestReactions, [reaction])
    }

    func test_middleware_handlesReactionNewEvent() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let messagePayload: MessagePayload = .dummy(messageId: messageId, authorUserId: .unique)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil)
            try session.saveMessage(payload: messagePayload, for: cid, syncOwnReactions: true)
        }

        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: messageId,
            user: UserPayload.dummy(userId: .unique)
        )
        
        // Create event payload.
        let user = UserPayload.dummy(userId: .unique)
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: cid,
            user: user,
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
            reaction: reactionPayload,
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try ReactionNewEventDTO(from: eventPayload)

        // Simulate `ReactionNewEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the message.
        let message = try XCTUnwrap(
            database.viewContext.message(id: messageId)
        )
        
        // Load the reaction.
        let reaction = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: messageId,
                userId: reactionPayload.user.id,
                type: reactionPayload.type
            )?.asModel()
        )
        
        XCTAssertTrue(forwardedEvent is ReactionNewEventDTO)
        try XCTAssertEqual(message.asModel().latestReactions, [reaction])
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
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
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

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReactionsMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: MessageReactionsMiddleware!
    
    // MARK: - Set up
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        middleware = .init()
    }
    
    override func tearDown() {
        middleware = nil
        AssertAsync.canBeReleased(&database)

        super.tearDown()
    }
    
    // MARK: - Tests
    
    func tests_middleware_forwardsNonReactionEvents() throws {
        let event = TestEvent()
        
        // Handle non-reaction event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }
    
    func tests_middleware_forwardsReactionEvent_ifDatabaseWriteGeneratesError() throws {
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: .unique,
            reaction: .dummy(
                messageId: .unique,
                user: UserPayload.dummy(userId: .unique)
            )
        )
        
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate and handle reaction event.
        let event = try ReactionNewEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `ReactionNewEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ReactionNewEvent)
    }
    
    func tests_middleware_handlesReactionNewEventCorrectly() throws {
        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: UserPayload.dummy(userId: .unique)
        )
        
        // Create event payload.
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: .unique,
            reaction: reactionPayload
        )
        
        // Create event with payload.
        let event = try ReactionNewEvent(from: eventPayload)
        
        // Create message in the database.
        try database.createMessage(id: reactionPayload.messageId)

        // Simulate `ReactionNewEvent` event.
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
            )
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is ReactionNewEvent)
        // Assert reaction is linked to the message.
        XCTAssertEqual(message.reactions, [reaction])
    }
    
    func tests_middleware_handlesReactionUpdatedEventCorrectly() throws {
        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: UserPayload.dummy(userId: .unique)
        )
        
        // Create event payload.
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: .unique,
            reaction: reactionPayload
        )
        
        // Create event with payload.
        let event = try ReactionUpdatedEvent(from: eventPayload)
        
        // Create message in the database.
        try database.createMessage(id: reactionPayload.messageId)

        // Simulate `ReactionNewEvent` event.
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
            )
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is ReactionUpdatedEvent)
        // Assert reaction is linked to the message.
        XCTAssertEqual(message.reactions, [reaction])
    }
    
    func tests_middleware_handlesReactionDeletedEventCorrectly() throws {
        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: UserPayload.dummy(userId: .unique)
        )
        
        // Create event payload.
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: .unique,
            reaction: reactionPayload
        )
        
        // Save message to the database.
        try database.createMessage(id: reactionPayload.messageId)
        
        // Save reaction to the database.
        try database.writeSynchronously { session in
            try session.saveReaction(payload: reactionPayload)
        }

        // Simulate `ReactionDeletedEvent` event.
        let event = try ReactionDeletedEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the message.
        let message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )
        
        // Load the reaction.
        var reaction: MessageReactionDTO? {
            database.viewContext.reaction(
                messageId: reactionPayload.messageId,
                userId: reactionPayload.user.id,
                type: reactionPayload.type
            )
        }
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is ReactionDeletedEvent)
        // Assert message reaction is deleted.
        XCTAssertNil(reaction)
        // Assert message reactions are empty.
        XCTAssertTrue(message.reactions.isEmpty)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}

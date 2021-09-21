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
        let user = UserPayload.dummy(userId: .unique)
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: .unique,
            user: user,
            message: .dummy(messageId: .unique, authorUserId: .unique),
            reaction: .dummy(
                messageId: .unique,
                user: user
            ),
            createdAt: .unique
        )
        
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate and handle reaction event.
        let event = try ReactionNewEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `ReactionNewEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ReactionNewEventDTO)
    }
    
    func tests_middleware_handlesReactionNewEventCorrectly() throws {
        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: UserPayload.dummy(userId: .unique)
        )
        
        // Create event payload.
        let user = UserPayload.dummy(userId: .unique)
        let eventPayload: EventPayload = .init(
            eventType: .reactionNew,
            cid: .unique,
            user: user,
            message: .dummy(messageId: .unique, authorUserId: .unique),
            reaction: reactionPayload,
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try ReactionNewEventDTO(from: eventPayload)
        
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
        XCTAssertTrue(forwardedEvent is ReactionNewEventDTO)
        // Assert reaction is linked to the message.
        XCTAssertEqual(message.reactions, [reaction])
    }
    
    func tests_middleware_handlesReactionUpdatedEventCorrectly() throws {
        let user = UserPayload.dummy(userId: .unique)

        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: user
        )
        
        // Create event payload.
        let eventPayload: EventPayload = .init(
            eventType: .reactionUpdated,
            cid: .unique,
            user: user,
            message: .dummy(messageId: .unique, authorUserId: .unique),
            reaction: reactionPayload,
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try ReactionUpdatedEventDTO(from: eventPayload)
        
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
        XCTAssertTrue(forwardedEvent is ReactionUpdatedEventDTO)
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
            eventType: .reactionDeleted,
            cid: .unique,
            user: reactionPayload.user,
            message: .dummy(
                messageId: reactionPayload.messageId,
                authorUserId: reactionPayload.user.id
            ),
            reaction: reactionPayload,
            createdAt: .unique
        )
        
        // Save message to the database.
        try database.createMessage(id: reactionPayload.messageId)
        
        // Save reaction to the database.
        try database.writeSynchronously { session in
            try session.saveReaction(payload: reactionPayload)
        }

        // Simulate `ReactionDeletedEvent` event.
        let event = try ReactionDeletedEventDTO(from: eventPayload)
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
        XCTAssertTrue(forwardedEvent is ReactionDeletedEventDTO)
        // Assert message reaction is deleted.
        XCTAssertNil(reaction)
        // Assert message reactions are empty.
        XCTAssertTrue(message.reactions.isEmpty)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}

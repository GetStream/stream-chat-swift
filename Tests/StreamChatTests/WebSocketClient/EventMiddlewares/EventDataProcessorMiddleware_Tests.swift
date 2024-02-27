//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        database = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    func test_eventWithPayload_isSavedToDB() throws {
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)

        let testEvent = NotificationAddedToChannelEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            type: EventType.notificationAddedToChannel.rawValue,
            channel: channelPayload.channel
        )

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

        let reactionPayload: Reaction = .dummy(
            messageId: messageId,
            user: .dummy(userId: .unique)
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
                for: cid, syncOwnReactions: true,
                cache: nil
            )
        }

        var message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )

        // pre-condition check
        XCTAssertFalse(message.latestReactions.isEmpty)

        // Simulate `ReactionDeletedEvent` event.
        let event = ReactionDeletedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.reactionDeleted.rawValue,
            message: .dummy(messageId: messageId, authorUserId: reactionPayload.user!.id),
            reaction: reactionPayload,
            user: reactionPayload.user
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the message.
        message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )

        XCTAssertTrue(forwardedEvent is ReactionDeletedEvent)
        XCTAssertTrue(message.latestReactions.isEmpty)
    }

    func test_middleware_handlesReactionUpdated() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let messagePayload: Message = .dummy(messageId: messageId, authorUserId: .unique)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(payload: messagePayload, for: cid, syncOwnReactions: true, cache: nil)
        }

        let user = UserObject.dummy(userId: .unique)

        // Create reaction payload.
        let reactionPayload: Reaction = .dummy(
            messageId: messageId,
            user: user
        )

        // Create event with payload.
        let event = ReactionUpdatedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.reactionUpdated.rawValue,
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
            reaction: reactionPayload,
            user: user
        )

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
                userId: reactionPayload.user!.id,
                type: MessageReactionType(rawValue: reactionPayload.type)
            )?.asModel()
        )

        XCTAssertTrue(forwardedEvent is ReactionUpdatedEvent)
        try XCTAssertEqual(message.asModel().latestReactions, [reaction])
    }

    func test_middleware_handlesReactionNewEvent() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let messagePayload: Message = .dummy(messageId: messageId, authorUserId: .unique)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(payload: messagePayload, for: cid, syncOwnReactions: true, cache: nil)
        }

        // Create reaction payload.
        let reactionPayload: Reaction = .dummy(
            messageId: messageId,
            user: UserObject.dummy(userId: .unique)
        )

        let user = UserObject.dummy(userId: .unique)
        // Create event with payload.
        let event = ReactionNewEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.reactionNew.rawValue,
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
            reaction: reactionPayload,
            user: user
        )

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
                userId: reactionPayload.user!.id,
                type: MessageReactionType(rawValue: reactionPayload.type)
            )?.asModel()
        )

        XCTAssertTrue(forwardedEvent is ReactionNewEvent)
        try XCTAssertEqual(message.asModel().latestReactions, [reaction])
    }

    func test_eventWithInvalidPayload_isNotForwarded() throws {
        // Create dummy event payload
        let testEvent = UserUpdatedEvent(
            createdAt: .unique,
            type: EventType.userUpdated.rawValue,
            user: .dummy(userId: .unique)
        )

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

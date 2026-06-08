//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let channel = try XCTUnwrap(channelPayload.channel)
        let dto = NotificationAddedToChannelEventDTO(
            channel: channel,
            cid: channelId.rawValue,
            createdAt: Date(),
            custom: [:],
            member: channel.members?.first ?? .dummy()
        )

        // Let the middleware handle the event
        let outputEvent = middleware.handle(
            event: dto,
            wsEvent: .typeNotificationAddedToChannelEvent(dto),
            session: database.viewContext
        )

        // Assert the channel data is saved and the event is forwarded
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }
        XCTAssertEqual(loadedChannel?.cid, channelId)
        XCTAssertEqual(outputEvent?.asEquatable, dto.asEquatable)
    }

    func test_middleware_handlesReactionDeletedEvent() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        let reactionPayload: ReactionResponse = .dummy(
            messageId: messageId,
            user: UserResponse.dummy(userId: .unique)
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

        let event = ReactionDeletedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: .dummy(messageId: messageId, authorUserId: reactionPayload.user.id),
            messageId: messageId,
            reaction: reactionPayload,
            user: UserResponseCommonFields(reactionPayload.user)
        )

        // Simulate `ReactionDeletedEvent` event.
        let forwardedEvent = middleware.handle(
            event: event,
            wsEvent: .typeReactionDeletedEvent(event),
            session: database.viewContext
        )

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
        let messagePayload: MessageResponse = .dummy(messageId: messageId, authorUserId: .unique)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(payload: messagePayload, for: cid, syncOwnReactions: true, cache: nil)
        }

        let user = UserResponse.dummy(userId: .unique)

        // Create reaction payload.
        let reactionPayload: ReactionResponse = .dummy(
            messageId: messageId,
            user: user
        )

        // Create event DTO.
        let event = ReactionUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
            messageId: messageId,
            reaction: reactionPayload,
            user: UserResponseCommonFields(user)
        )

        // Simulate `ReactionUpdatedEvent` event.
        let forwardedEvent = middleware.handle(
            event: event,
            wsEvent: .typeReactionUpdatedEvent(event),
            session: database.viewContext
        )

        // Load the message.
        let message = try XCTUnwrap(
            database.viewContext.message(id: reactionPayload.messageId)
        )

        // Load the reaction.
        let reaction = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: reactionPayload.messageId,
                userId: reactionPayload.user.id,
                type: MessageReactionType(rawValue: reactionPayload.type)
            )?.asModel()
        )

        XCTAssertTrue(forwardedEvent is ReactionUpdatedEventDTO)
        try XCTAssertEqual(message.asModel().latestReactions, [reaction])
    }

    func test_middleware_handlesReactionNewEvent() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let messagePayload: MessageResponse = .dummy(messageId: messageId, authorUserId: .unique)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(payload: messagePayload, for: cid, syncOwnReactions: true, cache: nil)
        }

        // Create reaction payload.
        let reactionPayload: ReactionResponse = .dummy(
            messageId: messageId,
            user: UserResponse.dummy(userId: .unique)
        )

        // Create event DTO.
        let user = UserResponse.dummy(userId: .unique)
        let event = ReactionNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload]),
            messageId: messageId,
            reaction: reactionPayload,
            user: UserResponseCommonFields(user)
        )

        // Simulate `ReactionNewEvent` event.
        let forwardedEvent = middleware.handle(
            event: event,
            wsEvent: .typeReactionNewEvent(event),
            session: database.viewContext
        )

        // Load the message.
        let message = try XCTUnwrap(
            database.viewContext.message(id: messageId)
        )

        // Load the reaction.
        let reaction = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: messageId,
                userId: reactionPayload.user.id,
                type: MessageReactionType(rawValue: reactionPayload.type)
            )?.asModel()
        )

        XCTAssertTrue(forwardedEvent is ReactionNewEventDTO)
        try XCTAssertEqual(message.asModel().latestReactions, [reaction])
    }

    func test_eventWithInvalidPayload_isNotForwarded() throws {
        // Create dummy event DTO
        let user = UserResponse.dummy(userId: .unique)
        let testEvent = UserUpdatedEventDTO(
            createdAt: .unique,
            custom: [:],
            user: UserResponsePrivacyFields(user)
        )

        // Simulate the DB fails to save the payload
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
        session.errorToReturn = TestError()

        // Let the middleware handle the event
        let outputEvent = middleware.handle(
            event: testEvent,
            wsEvent: .typeUserUpdatedEvent(testEvent),
            session: session
        )

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

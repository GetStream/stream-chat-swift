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
        // Prepare an Event with a payload with channel data
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)

        let testEvent = NotificationAddedToChannelEventDTO(
            channel: channelPayload.channel,
            createdAt: .unique,
            member: .dummy()
        )

        // Let the middleware handle the event
        let outputEvent = middleware.handle(event: testEvent, wsEvent: .typeNotificationAddedToChannelEvent(testEvent), session: database.viewContext)

        // Assert the channel data is saved and the event is forwarded
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }
        XCTAssertEqual(loadedChannel?.cid, channelId)
        XCTAssertEqual(outputEvent?.asEquatable, testEvent.asEquatable)
    }

    func test_channelUpdated_thenMemberUpdatedWithOlderChannel_doesNotRewindChannelState() throws {
        let cid: ChannelId = .unique
        let memberId: UserId = .unique
        let newerUpdatedAt = Date(timeIntervalSince1970: 2000)
        let olderUpdatedAt = Date(timeIntervalSince1970: 1940)
        let newerExtraData: [String: RawJSON] = ["state": .string("conversation"), "revision": .number(2)]
        let olderExtraData: [String: RawJSON] = ["state": .string("initiated"), "revision": .number(1)]
        let updatedMemberExtraData: [String: RawJSON] = ["status": .string("updated")]

        nonisolated(unsafe) let middlewares: [EventMiddleware] = [
            EventDataProcessorMiddleware(),
            MemberEventMiddleware()
        ]

        let channelUpdatedEvent = ChannelUpdatedEventDTO(
            channel: .dummy(
                cid: cid,
                name: "Conversation",
                extraData: newerExtraData,
                updatedAt: newerUpdatedAt,
                isFrozen: true,
                memberCount: 1
            ),
            createdAt: newerUpdatedAt
        )

        let memberUpdatedEvent = MemberUpdatedEventDTO(
            channel: .dummy(
                cid: cid,
                name: "Initiated",
                extraData: olderExtraData,
                updatedAt: olderUpdatedAt,
                isFrozen: false,
                memberCount: 2
            ),
            cid: cid,
            createdAt: newerUpdatedAt.addingTimeInterval(0.03),
            member: .dummy(user: .dummy(userId: memberId), extraData: updatedMemberExtraData),
            user: .dummy(userId: memberId)
        )

        try database.writeSynchronously { session in
            _ = middlewares.process(event: channelUpdatedEvent, wsEvent: .typeChannelUpdatedEvent(channelUpdatedEvent), session: session)
            _ = middlewares.process(event: memberUpdatedEvent, wsEvent: .typeMemberUpdatedEvent(memberUpdatedEvent), session: session)
        }

        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid)?.asModel())
        XCTAssertEqual(channel.name, "Conversation")
        XCTAssertEqual(channel.extraData, newerExtraData)
        XCTAssertEqual(channel.updatedAt, newerUpdatedAt)
        XCTAssertEqual(channel.memberCount, 1)
        XCTAssertTrue(channel.isFrozen)

        let member = try XCTUnwrap(database.viewContext.member(userId: memberId, cid: cid)?.asModel())
        XCTAssertEqual(member.memberExtraData, updatedMemberExtraData)
    }

    func test_middleware_handlesReactionDeletedEvent() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: messageId,
            user: UserPayload.dummy(userId: .unique)
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload], cid: cid),
                syncOwnReactions: true,
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
            cid: cid,
            createdAt: .unique,
            message: .dummy(
                messageId: messageId,
                authorUserId: reactionPayload.user.id,
                cid: cid
            ),
            reaction: reactionPayload,
            user: reactionPayload.user
        )

        // Simulate `ReactionDeletedEvent` event.
        let forwardedEvent = middleware.handle(event: event, wsEvent: .typeReactionDeletedEvent(event), session: database.viewContext)

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
        let messagePayload: MessagePayload = .dummy(messageId: messageId, authorUserId: .unique, cid: cid)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(payload: messagePayload, syncOwnReactions: true, cache: nil)
        }

        let user = UserPayload.dummy(userId: .unique)

        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: messageId,
            user: user
        )

        // Create event payload.
        let event = ReactionUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: .unique,
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload], cid: cid),
            reaction: reactionPayload,
            user: user
        )

        // Simulate `ReactionUpdatedEvent` event.
        let forwardedEvent = middleware.handle(event: event, wsEvent: .typeReactionUpdatedEvent(event), session: database.viewContext)

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
        let messagePayload: MessagePayload = .dummy(messageId: messageId, authorUserId: .unique, cid: cid)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(payload: messagePayload, syncOwnReactions: true, cache: nil)
        }

        // Create reaction payload.
        let reactionPayload: MessageReactionPayload = .dummy(
            messageId: messageId,
            user: UserPayload.dummy(userId: .unique)
        )

        // Create event payload.
        let user = UserPayload.dummy(userId: .unique)
        let event = ReactionNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: .unique,
            message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [reactionPayload], cid: cid),
            reaction: reactionPayload,
            user: user
        )

        // Simulate `ReactionNewEvent` event.
        let forwardedEvent = middleware.handle(event: event, wsEvent: .typeReactionNewEvent(event), session: database.viewContext)

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
        let testEvent = UserUpdatedEventDTO(
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        // Simulate the DB fails to save the payload
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
        session.errorToReturn = TestError()

        // Let the middleware handle the event
        let outputEvent = middleware.handle(event: testEvent, wsEvent: .typeUserUpdatedEvent(testEvent), session: session)

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

    func test_connectedEvent_savesCurrentUser() throws {
        let currentUserId = UserId.unique
        let connectedEvent = ConnectedEvent(connectionId: .unique, me: .dummy(userId: currentUserId))

        // Let the middleware handle the event
        let outputEvent = middleware.handle(event: connectedEvent, session: database.viewContext)

        // Assert the current user is saved and the event is forwarded
        XCTAssertEqual(database.viewContext.currentUser?.user.id, currentUserId)
        XCTAssertTrue(outputEvent is ConnectedEvent)
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ReactionEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder()
    let userId = "broken-waterfall-5"
    let cid = ChannelId(type: .messaging, id: "general")
    let messageId = "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
    
    func test_new() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEventDTO
        let reactionPayload = event?.payload.reaction
        XCTAssertEqual(event?.user.id, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction.type, "like")
        XCTAssertEqual(event?.reaction.score, 1)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEventDTO
        let reactionPayload = event?.payload.reaction
        XCTAssertEqual(event?.user.id, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction.type, "like")
        XCTAssertEqual(event?.reaction.score, 2)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEventDTO
        let reactionPayload = event?.payload.reaction
        XCTAssertEqual(event?.user.id, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction.type, "like")
        XCTAssertEqual(event?.reaction.score, 1)
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
}

class ReactionEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false
        
        currentUserId = .unique
        client = ChatClient(
            config: config,
            environment: .withZeroEventBatchingPeriod
        )
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_ReactionNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEventDTO
        
        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )
        
        try client.databaseContainer.createMessage(
            id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779", cid: .init(type: .messaging, id: "general")
        )
        
        XCTAssertTrue(
            client.databaseContainer.viewContext.message(id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779")?.latestReactions
                .isEmpty ?? false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.latestReactions.isEmpty ?? true
            )
        }
    }
    
    func test_ReactionUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEventDTO
        
        let newReactionJSON = XCTestCase.mockData(fromFile: "ReactionNew")
        let newReactionEvent = try eventDecoder.decode(from: newReactionJSON) as? ReactionNewEventDTO
        let newReactionPayload = try XCTUnwrap(newReactionEvent?.payload.reaction)
        
        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )
    
        let lastUpdateMessageTime = "2020-06-20 17:09:56 +0000"
        
        try client.databaseContainer.createMessage(
            id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779",
            latestReactions: [newReactionPayload],
            type: .regular
        )
        
        XCTAssertEqual(
            client.databaseContainer.viewContext.message(
                id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
            )?.asModel().latestReactions.first?.updatedAt.description,
            lastUpdateMessageTime
        )
        
        let unwrappedUpdate = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedUpdate)
        
        AssertAsync {
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.asModel().latestReactions.first?.updatedAt.description,
                "2020-07-20 17:09:56 +0000"
            )
        }
    }
    
    func test_ReactionDeletedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEventDTO
        
        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )
        
        try client.databaseContainer.createMessage(
            id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779", cid: .init(type: .messaging, id: "general")
        )
        
        XCTAssertTrue(
            client.databaseContainer.viewContext.message(id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779")?.latestReactions
                .isEmpty ?? false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.latestReactions.isEmpty ?? true
            )
        }
    }
    
    // MARK: DTO -> Event
    
    func test_reactionNewEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let channel: ChannelDetailPayload = .dummy(cid: .unique)
        let message: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)
        let user: UserPayload = .dummy(userId: .unique)
        let reaction: MessageReactionPayload = .dummy(messageId: message.id, user: user)
        
        let eventPayload = EventPayload(
            eventType: .reactionNew,
            cid: channel.cid,
            user: user,
            channel: channel,
            message: message,
            reaction: reaction,
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ReactionNewEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil)
        _ = try session.saveMessage(payload: message, for: channel.cid)
        try session.saveReaction(payload: reaction)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ReactionNewEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.reaction.type, eventPayload.reaction?.type)
        XCTAssertEqual(event.reaction.score, eventPayload.reaction?.score)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_reactionUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let channel: ChannelDetailPayload = .dummy(cid: .unique)
        let message: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)
        let user: UserPayload = .dummy(userId: .unique)
        let reaction: MessageReactionPayload = .dummy(messageId: message.id, user: user)
        
        let eventPayload = EventPayload(
            eventType: .reactionUpdated,
            cid: channel.cid,
            user: user,
            channel: channel,
            message: message,
            reaction: reaction,
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ReactionUpdatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil)
        _ = try session.saveMessage(payload: message, for: channel.cid)
        try session.saveReaction(payload: reaction)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ReactionUpdatedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.reaction.type, eventPayload.reaction?.type)
        XCTAssertEqual(event.reaction.score, eventPayload.reaction?.score)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_reactionDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let channel: ChannelDetailPayload = .dummy(cid: .unique)
        let message: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)
        let user: UserPayload = .dummy(userId: .unique)
        let reaction: MessageReactionPayload = .dummy(messageId: message.id, user: user)
        
        let eventPayload = EventPayload(
            eventType: .reactionDeleted,
            cid: channel.cid,
            user: user,
            channel: channel,
            message: message,
            reaction: reaction,
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ReactionDeletedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil)
        _ = try session.saveMessage(payload: message, for: channel.cid)
        try session.saveReaction(payload: reaction)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ReactionDeletedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.reaction.type, eventPayload.reaction?.type)
        XCTAssertEqual(event.reaction.score, eventPayload.reaction?.score)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

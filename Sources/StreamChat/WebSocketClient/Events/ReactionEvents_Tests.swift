//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ReactionEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<NoExtraData>()
    let userId = "broken-waterfall-5"
    let cid = ChannelId(type: .messaging, id: "general")
    let messageId = "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
    
    func test_new() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEvent
        let reactionPayload = (event?.payload as? EventPayload<NoExtraData>)?[keyPath: \.reaction]
        XCTAssertEqual(event?.userId, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reactionType, "like")
        XCTAssertEqual(event?.reactionScore, 1)
        XCTAssertEqual(event?.createdAt.description, "2020-06-20 17:09:56 +0000")
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEvent
        let reactionPayload = (event?.payload as? EventPayload<NoExtraData>)?[keyPath: \.reaction]
        XCTAssertEqual(event?.userId, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reactionType, "like")
        XCTAssertEqual(event?.reactionScore, 2)
        XCTAssertEqual(event?.updatedAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEvent
        let reactionPayload = (event?.payload as? EventPayload<NoExtraData>)?[keyPath: \.reaction]
        XCTAssertEqual(event?.userId, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reactionType, "like")
        XCTAssertEqual(event?.reactionScore, 1)
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
}

class ReactionEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder<NoExtraData>()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false
        
        currentUserId = .unique
        client = ChatClient(config: config)
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.eventNotificationCenter.eventBatchPeriod = 0
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_ReactionNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEvent
        
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
            client.databaseContainer.viewContext.message(id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779")?.reactions.isEmpty ?? false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.reactions.isEmpty ?? true
            )
        }
    }
    
    func test_ReactionUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEvent
        
        let newReactionJSON = XCTestCase.mockData(fromFile: "ReactionNew")
        let newReactionEvent = try eventDecoder.decode(from: newReactionJSON) as? ReactionNewEvent
        let newReactionPayload = try XCTUnwrap((newReactionEvent?.payload as? EventPayload<NoExtraData>)?.reaction)
        
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
            )?.reactions.first?.updatedAt.description,
            lastUpdateMessageTime
        )
        
        let unwrappedUpdate = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedUpdate)
        
        AssertAsync {
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.reactions.first?.updatedAt.description,
                "2020-07-20 17:09:56 +0000"
            )
        }
    }
    
    func test_ReactionDeletedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEvent
        
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
            client.databaseContainer.viewContext.message(id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779")?.reactions.isEmpty ?? false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.reactions.isEmpty ?? true
            )
        }
    }
}

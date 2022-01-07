//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class TypingEvent_Tests: XCTestCase {
    var eventDecoder: EventDecoder!
    var cid: ChannelId = ChannelId(type: .messaging, id: "general")
    var userId = "luke_skywalker"

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    func test_parseTypingStartEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, userId)
    }
    
    func test_parseTypingStoptEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertFalse(event.isTyping)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, userId)
        XCTAssertFalse(event.isThread)
    }

    func test_parseTypingStartEventInThread() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertTrue(event.isThread)
    }
    
    func test_parseTypingStoptEventInThread() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertFalse(event.isTyping)
        XCTAssertTrue(event.isThread)
    }
    
    // MARK: DTO -> Event
    
    func test_startTypingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userStartTyping,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            parentId: .unique
        )
        
        // Create event DTO
        let dto = try TypingEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isTyping, true)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.parentId, eventPayload.parentId)
        XCTAssertEqual(event.isThread, true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_stopTypingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userStopTyping,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try TypingEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isTyping, false)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.parentId, nil)
        XCTAssertEqual(event.isThread, false)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

class TypingEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder()

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

    func test_UserStartTypingEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTyping")
        let event = try eventDecoder.decode(from: json) as? TypingEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "general")
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        try client.databaseContainer.createMember(userId: "luke_skywalker", role: .member, cid: channelId)
        
        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingUsers.isEmpty ?? true
            )
        }
    }
    
    func test_UserStopTypingEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTyping")
        let event = try eventDecoder.decode(from: json) as? TypingEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "general")
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false,
            withQuery: false
        )

        try client.databaseContainer.createUser(id: "luke_skywalker")
        
        // Insert synchronously typing member into channel:
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: channelId))
            let user = try XCTUnwrap(session.user(id: "luke_skywalker"))
            channel.currentlyTypingUsers.insert(user)
        }
        
        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertFalse(channel.currentlyTypingUsers.isEmpty)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingUsers.isEmpty ?? false
            )
        }
    }
}

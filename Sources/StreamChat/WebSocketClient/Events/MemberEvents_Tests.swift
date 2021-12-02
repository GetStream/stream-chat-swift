//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class MemberEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder()
    
    func test_added() throws {
        let json = XCTestCase.mockData(fromFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEventDTO
        XCTAssertEqual(event?.member.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEventDTO
        XCTAssertEqual(event?.member.user.id, "count_dooku")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"))
    }
    
    func test_removed() throws {
        let json = XCTestCase.mockData(fromFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEventDTO
        XCTAssertEqual(event?.user.id, "r2-d2")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"))
    }
    
    // MARK: DTO -> Event
    
    func test_memberAddedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .memberAdded,
            cid: .unique,
            user: .dummy(userId: .unique),
            memberContainer: .init(
                member: .dummy(),
                invite: nil,
                memberRole: nil
            ),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try MemberAddedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        try session.saveMember(payload: eventPayload.memberContainer!.member!, channelId: eventPayload.cid!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MemberAddedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user.id)
        XCTAssertEqual(event.member.memberRole, eventPayload.memberContainer?.member?.role)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_memberUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .memberUpdated,
            cid: .unique,
            user: .dummy(userId: .unique),
            memberContainer: .init(
                member: .dummy(),
                invite: nil,
                memberRole: nil
            ),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try MemberUpdatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        try session.saveMember(payload: eventPayload.memberContainer!.member!, channelId: eventPayload.cid!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MemberUpdatedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user.id)
        XCTAssertEqual(event.member.memberRole, eventPayload.memberContainer?.member?.role)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_memberRemovedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .memberRemoved,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try MemberRemovedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MemberRemovedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

class MemberEventsIntegration_Tests: XCTestCase {
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
            workerBuilders: [],
            environment: .withZeroEventBatchingPeriod
        )
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }
    
    func test_MemberAddedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEventDTO
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willNotBeNil(
                self.client.databaseContainer.viewContext.member(
                    userId: "steep-moon-9",
                    cid: ChannelId(type: .messaging, id: "new_channel_9125")
                )
            )
        }
    }

    func test_MemberUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEventDTO
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willNotBeNil(
                self.client.databaseContainer.viewContext.member(
                    userId: "count_dooku",
                    cid: ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
                )
            )
        }
    }
    
    func test_MemberRemovedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEventDTO
        
        let channelId = ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
        
        // First create channel and member of that channel to be saved in database.
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false,
            withQuery: false
        )
        
        try! client.databaseContainer.createMember(
            userId: "r2-d2",
            role: .member,
            cid: ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"),
            query: nil
        )
        
        // Check if those are created in order to avoid false-positive.
        XCTAssertTrue(
            client.databaseContainer.viewContext.channel(cid: channelId)?.members.contains { $0.user.id == "r2-d2" } ?? false
        )
        
        XCTAssertNotNil(
            client.databaseContainer.viewContext.channel(cid: channelId)
        )
        
        // Channel should contain current user and r2-d2.
        XCTAssertTrue(client.databaseContainer.viewContext.channel(cid: channelId)?.members.count == 2)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        AssertAsync.willBeFalse(
            client.databaseContainer.viewContext.channel(cid: channelId)?.members.contains { $0.user.id == "r2-d2" } ?? true
        )
    }
}

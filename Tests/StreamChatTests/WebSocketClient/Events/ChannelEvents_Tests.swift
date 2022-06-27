//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.payload.user?.id, "broken-waterfall-5")
    }
    
    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertNil(event?.payload.user?.id)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "default-channel-1"))
        XCTAssertEqual(event?.createdAt.description, "2021-04-23 09:38:47 +0000")
        XCTAssertEqual(
            event?.payload.channel?.cid,
            ChannelId(type: .messaging, id: "default-channel-1")
        )
    }
    
    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromJSONFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, false)

        json = XCTestCase.mockData(fromJSONFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, true)
    }
    
    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }
    
    func test_visible() throws {
        // Channel is visible again.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7011"))
        XCTAssertNil(event?.message)

        let rawPayload = try JSONDecoder.stream.decode(EventPayload.self, from: mockData)
        XCTAssertEqual(event?.payload.createdAt, rawPayload.createdAt)
    }
    
    func test_channelTruncatedEventWithMessage() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated_with_message")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "8372DE11-E"))

        let rawPayload = try JSONDecoder.stream.decode(EventPayload.self, from: mockData)
        XCTAssertEqual(event?.payload.createdAt, rawPayload.createdAt)
        XCTAssertEqual(event?.message?.text, "Channel truncated")
        XCTAssertEqual(event?.message?.type, .system)
    }
    
    // MARK: DTO -> Event
    
    func test_channelUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .channelUpdated,
            cid: cid,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelUpdatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        _ = try session.saveMessage(payload: eventPayload.message!, for: cid, cache: nil)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelUpdatedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.message?.id, eventPayload.message?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelDeleted,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelDeletedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelDeletedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelTruncatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelTruncated,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelTruncatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelTruncatedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelVisibleEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelVisible,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelVisibleEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelVisibleEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelHiddenEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelHidden,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            isChannelHistoryCleared: true
        )
        
        // Create event DTO
        let dto = try ChannelHiddenEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelHiddenEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isHistoryCleared, eventPayload.isChannelHistoryCleared)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

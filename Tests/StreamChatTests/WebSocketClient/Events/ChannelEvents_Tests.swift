//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    func test_created() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelCreated")
        XCTAssertThrowsError(try eventDecoder.decode(from: json)) { error in
            XCTAssertTrue(error is ClientError.EventDecoding)
        }
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:new_channel_7070")
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
    }

    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:new_channel_7070")
        XCTAssertNil(event?.user?.id)
    }

    func test_deleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ChannelDeletedEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:default-channel-1")
        XCTAssertEqual(event?.createdAt.description, "2021-04-23 09:38:47 +0000")
        XCTAssertEqual(
            event?.channel.cid,
            "messaging:default-channel-1"
        )
    }

    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromJSONFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decode(from: json).unwrappedEvent as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, "messaging:default-channel-6")
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.clearHistory, false)

        json = XCTestCase.mockData(fromJSONFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decode(from: json).unwrappedEvent as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, "messaging:default-channel-6")
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.clearHistory, true)
    }

    func test_ChannelHiddenEvent_syncReplay_decoding() throws {
        // /chat/sync replays channel.hidden without `clear_history` and with an
        // empty `channel.config` object.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelHidden+SyncReplay")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json).unwrappedEvent as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, "messaging:D74FA55F-C")
        XCTAssertNil(event.clearHistory)

        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let user: UserResponse = .dummy(userId: "r2-d2")
        try session.saveUser(payload: user)
        let domainEvent = try XCTUnwrap(event.toDomainEvent(session: session) as? ChannelHiddenEvent)
        XCTAssertFalse(domainEvent.isHistoryCleared)
    }

    func test_ChannelVisibleEvent_syncReplay_decoding() throws {
        // /chat/sync replays channel.visible with NO `channel` object at all.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible+SyncReplay")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json).unwrappedEvent as? ChannelVisibleEventDTO)
        XCTAssertEqual(event.cid, "messaging:1568ED7D-1")
        XCTAssertNil(event.channel)

        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let user: UserResponse = .dummy(userId: "r2-d2")
        try session.saveUser(payload: user)
        let domainEvent = try XCTUnwrap(event.toDomainEvent(session: session) as? ChannelVisibleEvent)
        XCTAssertEqual(domainEvent.cid.rawValue, "messaging:1568ED7D-1")
    }

    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, "messaging:default-channel-6")
    }

    func test_visible() throws {
        // Channel is visible again.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, "messaging:default-channel-6")
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated")

        let event = try eventDecoder.decode(from: mockData).unwrappedEvent as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:new_channel_7011")
        XCTAssertNil(event?.message)
        XCTAssertNotNil(event?.createdAt)
    }

    func test_channelTruncatedEventWithMessage() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated_with_message")

        let event = try eventDecoder.decode(from: mockData).unwrappedEvent as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:8372DE11-E")
        XCTAssertNotNil(event?.createdAt)
        XCTAssertEqual(event?.message?.text, "Channel truncated")
        XCTAssertEqual(event?.message?.type, MessageType.system.rawValue)
    }

    // MARK: DTO -> Event

    func test_channelUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let channel: ChannelResponse = .dummy(cid: cid)
        let message: MessageResponse = .dummy(messageId: .unique, authorUserId: .unique)
        let createdAt: Date = .unique
        let dto = ChannelUpdatedEventDTO(
            channel: channel,
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            message: message,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)
        _ = try session.saveMessage(payload: message, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelUpdatedEvent)
        XCTAssertEqual(event.user?.id, user.id)
        XCTAssertEqual(event.message?.id, message.id)
        XCTAssertEqual(event.channel.cid.rawValue, channel.cid)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_channelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let channel: ChannelResponse = .dummy(cid: .unique)
        let createdAt: Date = .unique
        let dto = ChannelDeletedEventDTO(
            channel: channel,
            createdAt: createdAt,
            custom: [:],
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelDeletedEvent)
        XCTAssertEqual(event.user?.id, user.id)
        XCTAssertEqual(event.channel.cid.rawValue, channel.cid)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_channelTruncatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let channel: ChannelResponse = .dummy(cid: .unique)
        let createdAt: Date = .unique
        let dto = ChannelTruncatedEventDTO(
            channel: channel,
            createdAt: createdAt,
            custom: [:],
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelTruncatedEvent)
        XCTAssertEqual(event.user?.id, user.id)
        XCTAssertEqual(event.channel.cid.rawValue, channel.cid)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_channelVisibleEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let channel: ChannelResponse = .dummy(cid: cid)
        let createdAt: Date = .unique
        let dto = ChannelVisibleEventDTO(
            channel: channel,
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelVisibleEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_channelHiddenEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let channel: ChannelResponse = .dummy(cid: cid)
        let createdAt: Date = .unique
        let dto = ChannelHiddenEventDTO(
            channel: channel,
            cid: cid.rawValue,
            clearHistory: true,
            createdAt: createdAt,
            custom: [:],
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelHiddenEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.isHistoryCleared, true)
        XCTAssertEqual(event.createdAt, createdAt)
    }
}

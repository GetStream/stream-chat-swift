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
        do {
            _ = try eventDecoder.decode(from: json)
            XCTFail("Should not be able to decode it")
        } catch {
            XCTAssertTrue(error is ClientError.IgnoredEventType)
        }
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated")
        let event = try eventDecoder.decodeDTO(from: json) as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
    }

    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decodeDTO(from: json) as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertNil(event?.user?.id)
    }

    func test_deleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelDeleted")
        let event = try eventDecoder.decodeDTO(from: json) as? ChannelDeletedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "default-channel-1"))
        XCTAssertEqual(event?.createdAt.description, "2021-04-23 09:38:47 +0000")
        XCTAssertEqual(
            event?.channel.cid,
            ChannelId(type: .messaging, id: "default-channel-1")
        )
    }

    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromJSONFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decodeDTO(from: json) as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.clearHistory, false)

        json = XCTestCase.mockData(fromJSONFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decodeDTO(from: json) as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.clearHistory, true)
    }

    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decodeDTO(from: json) as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }

    func test_visible() throws {
        // Channel is visible again.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decodeDTO(from: json) as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated")

        let event = try eventDecoder.decodeDTO(from: mockData) as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7011"))
        XCTAssertNil(event?.message)

        XCTAssertEqual(event?.createdAt.description, "2021-03-04 10:09:59 +0000")
    }

    func test_channelTruncatedEventWithMessage() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated_with_message")

        let event = try eventDecoder.decodeDTO(from: mockData) as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "8372DE11-E"))

        XCTAssertEqual(event?.createdAt.description, "2022-02-16 08:20:13 +0000")
        XCTAssertEqual(event?.message?.text, "Channel truncated")
        XCTAssertEqual(event?.message?.type, MessageType.system.rawValue)
    }

    // MARK: DTO -> Event

    func test_channelUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = ChannelUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: .unique,
            custom: [:],
            message: .dummy(messageId: .unique, authorUserId: .unique, cid: cid),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)
        _ = try session.saveMessage(payload: eventPayload.message!, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? ChannelUpdatedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.message?.id, eventPayload.message?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_channelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = ChannelDeletedEventDTO(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            custom: [:],
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? ChannelDeletedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_channelTruncatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = ChannelTruncatedEventDTO(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            custom: [:],
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? ChannelTruncatedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_channelVisibleEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = ChannelVisibleEventDTO(
            channel: .dummy(),
            cid: .unique,
            createdAt: .unique,
            custom: [:],
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? ChannelVisibleEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_channelHiddenEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = ChannelHiddenEventDTO(
            channel: .dummy(),
            cid: .unique,
            clearHistory: true,
            createdAt: .unique,
            custom: [:],
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? ChannelHiddenEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isHistoryCleared, eventPayload.clearHistory)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

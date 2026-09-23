//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_userPresenceEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserPresence")
        let event = try eventDecoder.decodeDTO(from: json) as? UserPresenceChangedEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-16 15:44:19 +0000")
    }

    func test_watchingEvent() throws {
        var json = XCTestCase.mockData(fromJSONFile: "UserStartWatching")
        var event = try eventDecoder.decodeDTO(from: json) as? UserWatchingEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"))
        XCTAssertEqual(event?.user.id, "luke_skywalker")
        // Not exactly isStarted field on UserStartWatching event,
        // rather if it the event is START not STOP watching.
        XCTAssertTrue(event?.isStarted ?? false)

        json = XCTestCase.mockData(fromJSONFile: "UserStopWatching")
        event = try eventDecoder.decodeDTO(from: json) as? UserWatchingEventDTO
        XCTAssertEqual(event?.user.id, "luke_skywalker")
        XCTAssertFalse(event?.isStarted ?? false)
        XCTAssertTrue(event?.watcherCount ?? 0 > 0)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"))
    }

    func test_userBannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserBanned")
        let event = try eventDecoder.decodeDTO(from: json) as? UserBannedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.createdBy?.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.reason, "I don't like you 🤮")
        XCTAssertEqual(event?.shadow, true)
    }

    func test_userUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserUnbanned")
        let event = try eventDecoder.decodeDTO(from: json) as? UserUnbannedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
    }

    func test_userGloballyBannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserGloballyBanned")
        let event = try eventDecoder.decodeDTO(from: json) as? UserBannedEventDTO
        XCTAssertEqual(event?.user.id, "c-3po")
        XCTAssertEqual(event?.createdAt.description, "2022-09-22 07:59:24 +0000")
    }

    func test_userGloballyUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserGloballyUnbanned")
        let event = try eventDecoder.decodeDTO(from: json) as? UserUnbannedEventDTO
        XCTAssertEqual(event?.user.id, "c-3po")
        XCTAssertEqual(event?.createdAt.description, "2022-09-22 08:00:15 +0000")
    }

    // MARK: DTO -> Event

    func test_userPresenceChangedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserPresenceChangedEventDTO(
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserPresenceChangedEvent)
        XCTAssertEqual(event.createdAt, dto.createdAt)
        XCTAssertEqual(event.user.id, dto.user.id)
    }

    func test_userUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserUpdatedEventDTO(
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserUpdatedEvent)
        XCTAssertEqual(event.createdAt, dto.createdAt)
        XCTAssertEqual(event.user.id, dto.user.id)
    }

    func test_userStartWatchingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserWatchingStartEventDTO(
            cid: .unique,
            createdAt: .unique,
            user: .dummy(userId: .unique),
            watcherCount: 10
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserWatchingEvent)
        XCTAssertEqual(event.cid, dto.cid)
        XCTAssertEqual(event.isStarted, true)
        XCTAssertEqual(event.user.id, dto.user.id)
        XCTAssertEqual(event.createdAt, dto.createdAt)
        XCTAssertEqual(event.watcherCount, dto.watcherCount)
    }

    func test_userStopWatchingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserWatchingStopEventDTO(
            cid: .unique,
            createdAt: .unique,
            user: .dummy(userId: .unique),
            watcherCount: 10
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserWatchingEvent)
        XCTAssertEqual(event.cid, dto.cid)
        XCTAssertEqual(event.isStarted, false)
        XCTAssertEqual(event.user.id, dto.user.id)
        XCTAssertEqual(event.createdAt, dto.createdAt)
    }

    func test_userBannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserBannedEventDTO(
            cid: .unique,
            createdAt: .unique,
            createdBy: .dummy(userId: .unique),
            expiration: .unique,
            reason: .unique,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserBannedEvent)
        XCTAssertEqual(event.cid, dto.cid)
        XCTAssertEqual(event.user.id, dto.user.id)
        XCTAssertEqual(event.reason, dto.reason)
        XCTAssertEqual(event.ownerId, dto.createdBy?.id)
        XCTAssertEqual(event.expiredAt, dto.expiration)
        XCTAssertEqual(event.createdAt, dto.createdAt)
    }

    func test_userUnbannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserUnbannedEventDTO(
            cid: .unique,
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserUnbannedEvent)
        XCTAssertEqual(event.cid, dto.cid)
        XCTAssertEqual(event.user.id, dto.user.id)
        XCTAssertEqual(event.createdAt, dto.createdAt)
    }

    func test_userGloballyBannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserBannedEventDTO(
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserGloballyBannedEvent)
        XCTAssertEqual(event.user.id, dto.user.id)
        XCTAssertEqual(event.createdAt, dto.createdAt)
    }

    func test_userGloballyUnbannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let dto = UserUnbannedEventDTO(
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: dto.user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserGloballyUnbannedEvent)
        XCTAssertEqual(event.user.id, dto.user.id)
        XCTAssertEqual(event.createdAt, dto.createdAt)
    }
}

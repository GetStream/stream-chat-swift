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
        let event = try eventDecoder.decodeFixture(from: json).unwrappedEvent as? UserPresenceChangedEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-16 15:44:19 +0000")
    }

    func test_watchingEvent() throws {
        let expectedCid = ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE")

        let startJson = XCTestCase.mockData(fromJSONFile: "UserStartWatching")
        let startEvent = try eventDecoder.decodeFixture(from: startJson).unwrappedEvent as? UserWatchingStartEventDTO
        XCTAssertEqual(startEvent?.cid, expectedCid.rawValue)
        XCTAssertEqual(startEvent?.user.id, "luke_skywalker")

        let stopJson = XCTestCase.mockData(fromJSONFile: "UserStopWatching")
        let stopEvent = try eventDecoder.decodeFixture(from: stopJson).unwrappedEvent as? UserWatchingStopEventDTO
        XCTAssertEqual(stopEvent?.user.id, "luke_skywalker")
        XCTAssertTrue((stopEvent?.watcherCount ?? 0) > 0)
        XCTAssertEqual(stopEvent?.cid, expectedCid.rawValue)
    }

    func test_userBannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserBanned")
        let event = try eventDecoder.decodeFixture(from: json).unwrappedEvent as? UserBannedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.createdBy?.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, "messaging:new_channel_7070")
        XCTAssertEqual(event?.reason, "I don't like you 🤮")
        XCTAssertEqual(event?.shadow, true)
    }

    func test_userUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserUnbanned")
        let event = try eventDecoder.decodeFixture(from: json).unwrappedEvent as? UserUnbannedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, "messaging:new_channel_7070")
    }

    func test_userGloballyBannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserGloballyBanned")
        let event = try eventDecoder.decodeFixture(from: json).unwrappedEvent as? UserBannedEventDTO
        XCTAssertEqual(event?.user.id, "c-3po")
        XCTAssertEqual(event?.createdAt.description, "2022-09-22 07:59:24 +0000")
        XCTAssertNil(event?.cid)
    }

    func test_userGloballyUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserGloballyUnbanned")
        let event = try eventDecoder.decodeFixture(from: json).unwrappedEvent as? UserUnbannedEventDTO
        XCTAssertEqual(event?.user.id, "c-3po")
        XCTAssertEqual(event?.createdAt.description, "2022-09-22 08:00:15 +0000")
        XCTAssertNil(event?.cid)
    }

    // MARK: DTO -> Event

    func test_userPresenceChangedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let dto = UserPresenceChangedEventDTO(
            createdAt: createdAt,
            custom: [:],
            user: UserResponseCommonFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserPresenceChangedEvent)
        XCTAssertEqual(event.createdAt, createdAt)
        XCTAssertEqual(event.user.id, user.id)
    }

    func test_userUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let dto = UserUpdatedEventDTO(
            createdAt: createdAt,
            custom: [:],
            user: UserResponsePrivacyFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserUpdatedEvent)
        XCTAssertEqual(event.createdAt, createdAt)
        XCTAssertEqual(event.user.id, user.id)
    }

    func test_userStartWatchingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let watcherCount = 10
        let dto = UserWatchingStartEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            user: UserResponseCommonFields(user),
            watcherCount: watcherCount
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserWatchingEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.isStarted, true)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.createdAt, createdAt)
        XCTAssertEqual(event.watcherCount, watcherCount)
    }

    func test_userStopWatchingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let dto = UserWatchingStopEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            user: UserResponseCommonFields(user),
            watcherCount: 10
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserWatchingEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.isStarted, false)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_userBannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdBy: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let banReason: String = .unique
        let banExpiredAt: Date = .unique
        let dto = UserBannedEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            createdBy: UserResponseCommonFields(createdBy),
            custom: [:],
            expiration: banExpiredAt,
            reason: banReason,
            user: UserResponseCommonFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserBannedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.reason, banReason)
        XCTAssertEqual(event.ownerId, createdBy.id)
        XCTAssertEqual(event.expiredAt, banExpiredAt)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_userUnbannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let dto = UserUnbannedEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            user: UserResponseCommonFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserUnbannedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_userBannedEventDTO_toDomainEvent_whenMissingCID_returnsGlobalBanEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let bannedDTO = UserBannedEventDTO(
            createdAt: createdAt,
            custom: [:],
            user: UserResponseCommonFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(bannedDTO.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(bannedDTO.toDomainEvent(session: session) as? UserGloballyBannedEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_userUnbannedEventDTO_toDomainEvent_whenMissingCID_returnsGlobalUnbanEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let unbannedDTO = UserUnbannedEventDTO(
            createdAt: createdAt,
            custom: [:],
            user: UserResponseCommonFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(unbannedDTO.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(unbannedDTO.toDomainEvent(session: session) as? UserGloballyUnbannedEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }
}

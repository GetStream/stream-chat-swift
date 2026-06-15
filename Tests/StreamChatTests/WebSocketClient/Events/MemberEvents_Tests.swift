//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_added() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? MemberAddedEventDTO
        XCTAssertEqual(event?.member.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, "messaging:new_channel_9125")
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? MemberUpdatedEventDTO
        XCTAssertEqual(event?.member.userId, "count_dooku")
        XCTAssertEqual(event?.cid, "messaging:!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
    }

    func test_removed() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? MemberRemovedEventDTO
        XCTAssertEqual(event?.user?.id, "r2-d2")
        XCTAssertEqual(event?.cid, "messaging:!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
    }

    // The backend sends member events without the `channel` object and without
    // `teams`/`blocked_user_ids` on user objects; decode directly (no fixture
    // normalization) to exercise the raw production shape.

    func test_added_withMissingChannelAndUserListFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberAdded+MissingFields")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? MemberAddedEventDTO
        let dto = try XCTUnwrap(event)
        XCTAssertNil(dto.channel)
        XCTAssertEqual(dto.cid, "messaging:new_channel_9125")
        XCTAssertEqual(dto.member.userId, "steep-moon-9")
        XCTAssertNil(dto.user?.teams)
        XCTAssertNil(dto.user?.blockedUserIds)
        XCTAssertNil(dto.member.user?.teams)
        XCTAssertNil(dto.member.user?.blockedUserIds)
    }

    func test_updated_withMissingChannelAndUserListFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberUpdated+MissingFields")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? MemberUpdatedEventDTO
        let dto = try XCTUnwrap(event)
        XCTAssertNil(dto.channel)
        XCTAssertEqual(dto.cid, "messaging:new_channel_9125")
        XCTAssertEqual(dto.member.userId, "steep-moon-9")
        XCTAssertNil(dto.user?.teams)
        XCTAssertNil(dto.user?.blockedUserIds)
    }

    func test_removed_withMissingChannelAndUserListFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberRemoved+MissingFields")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? MemberRemovedEventDTO
        let dto = try XCTUnwrap(event)
        XCTAssertNil(dto.channel)
        XCTAssertEqual(dto.cid, "messaging:new_channel_9125")
        XCTAssertEqual(dto.user?.id, "steep-moon-9")
        XCTAssertNil(dto.user?.teams)
        XCTAssertNil(dto.user?.blockedUserIds)
    }

    // MARK: DTO -> Event

    func test_memberAddedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let member: ChannelMemberResponse = .dummy()
        let createdAt: Date = .unique
        let dto = MemberAddedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            member: member,
            user: user
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        try session.saveMember(payload: member, channelId: cid)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MemberAddedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.member.id, member.user?.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_memberUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let member: ChannelMemberResponse = .dummy()
        let createdAt: Date = .unique
        let dto = MemberUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            member: member,
            user: user
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        try session.saveMember(payload: member, channelId: cid)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MemberUpdatedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.member.id, member.user?.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_memberRemovedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let dto = MemberRemovedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            member: .dummy(),
            user: user
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MemberRemovedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let event = try eventDecoder.decode(from: json) as? MemberAddedEventDTO
        XCTAssertEqual(event?.member.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEventDTO
        XCTAssertEqual(event?.member.userId, "count_dooku")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"))
    }

    func test_removed() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEventDTO
        XCTAssertEqual(event?.user.id, "r2-d2")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"))
    }

    // MARK: DTO -> Event

    func test_memberAddedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

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
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user!.id)
        XCTAssertEqual(event.member.memberRole, eventPayload.memberContainer?.member?.role)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_memberUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

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
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user!.id)
        XCTAssertEqual(event.member.memberRole, eventPayload.memberContainer?.member?.role)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_memberRemovedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

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

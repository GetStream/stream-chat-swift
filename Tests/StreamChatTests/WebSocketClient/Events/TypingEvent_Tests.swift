//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TypingEvent_Tests: XCTestCase {
    var eventDecoder: EventDecoder!
    var cid: ChannelId = ChannelId(type: .messaging, id: "general")
    var userId = "luke_skywalker"

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_parseTypingStartEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStartTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, userId)
    }

    func test_parseTypingStoptEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStopTyping")
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
        let json = XCTestCase.mockData(fromJSONFile: "UserStartTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertTrue(event.isThread)
    }

    func test_parseTypingStoptEventInThread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStopTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertFalse(event.isTyping)
        XCTAssertTrue(event.isThread)
    }

    // MARK: DTO -> Event

    func test_startTypingEventDTO_toDomainEvent() throws {
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let eventPayload = EventPayload(
            eventType: .userStartTyping,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            parentId: .unique
        )
        let dto = try TypingEventDTO(from: eventPayload)

        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isTyping, true)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertNil(event.memberInfo)
        XCTAssertEqual(event.parentId, eventPayload.parentId)
        XCTAssertEqual(event.isThread, true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_stopTypingEventDTO_toDomainEvent() throws {
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let eventPayload = EventPayload(
            eventType: .userStopTyping,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        let dto = try TypingEventDTO(from: eventPayload)

        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isTyping, false)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.parentId, nil)
        XCTAssertEqual(event.isThread, false)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_parseTypingStartEvent_withMemberInfo() throws {
        let json = """
        {
          "type": "typing.start",
          "cid": "messaging:general",
          "user": {
            "id": "luke_skywalker",
            "role": "user",
            "created_at": "2020-12-07T11:36:47.059906Z",
            "updated_at": "2021-04-22T18:57:47.14206Z",
            "banned": false,
            "online": true,
            "name": "Luke"
          },
          "member": {
            "channel_role": "channel_member",
            "notifications_muted": false,
            "is_premium": true,
            "nickname": "Marty"
          },
          "created_at": "2021-04-22T22:05:51.726128615Z"
        }
        """.data(using: .utf8)!

        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? TypingEventDTO)

        XCTAssertEqual(event.user.id, userId)
        XCTAssertEqual(event.member?.channelRole, "channel_member")
        XCTAssertEqual(event.member?.custom?["is_premium"], .bool(true))
        XCTAssertEqual(event.member?.custom?["nickname"], .string("Marty"))

        let domainEvent = try XCTUnwrap(event.toDomainEvent(session: DatabaseContainer_Spy(kind: .inMemory).viewContext) as? TypingEvent)
        XCTAssertEqual(domainEvent.memberInfo?.channelRole, .member)
        XCTAssertEqual(domainEvent.memberInfo?.extraData["is_premium"], .bool(true))
        XCTAssertEqual(domainEvent.memberInfo?.extraData["nickname"], .string("Marty"))
    }
}

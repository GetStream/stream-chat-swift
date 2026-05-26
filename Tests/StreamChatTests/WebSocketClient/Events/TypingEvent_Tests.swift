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
        guard let event = try eventDecoder.decode(from: json) as? TypingStartEventDTO else {
            XCTFail()
            return
        }

        XCTAssertEqual(event.cid, cid.rawValue)
        XCTAssertEqual(event.user?.id, userId)
    }

    func test_parseTypingStoptEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStopTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingStopEventDTO else {
            XCTFail()
            return
        }

        XCTAssertEqual(event.cid, cid.rawValue)
        XCTAssertEqual(event.user?.id, userId)
        XCTAssertNil(event.parentId)
    }

    func test_parseTypingStartEventInThread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStartTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingStartEventDTO else {
            XCTFail()
            return
        }

        XCTAssertNotNil(event.parentId)
    }

    func test_parseTypingStoptEventInThread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStopTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingStopEventDTO else {
            XCTFail()
            return
        }

        XCTAssertNotNil(event.parentId)
    }

    // MARK: DTO -> Event

    func test_startTypingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let parentId: String = .unique
        let dto = TypingStartEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            parentId: parentId,
            user: UserResponseCommonFields(user)
        )

        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: user)

        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.isTyping, true)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.parentId, parentId)
        XCTAssertEqual(event.isThread, true)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_stopTypingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let createdAt: Date = .unique
        let dto = TypingStopEventDTO(
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
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.isTyping, false)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.parentId, nil)
        XCTAssertEqual(event.isThread, false)
        XCTAssertEqual(event.createdAt, createdAt)
    }
}

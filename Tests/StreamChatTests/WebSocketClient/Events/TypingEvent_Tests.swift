//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        let json = XCTestCase.mockData(fromFile: "UserStartTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, userId)
    }
    
    func test_parseTypingStoptEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTyping")
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
        let json = XCTestCase.mockData(fromFile: "UserStartTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertTrue(event.isThread)
    }
    
    func test_parseTypingStoptEventInThread() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEventDTO else {
            XCTFail()
            return
        }

        XCTAssertFalse(event.isTyping)
        XCTAssertTrue(event.isThread)
    }
    
    // MARK: DTO -> Event
    
    func test_startTypingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userStartTyping,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            parentId: .unique
        )
        
        // Create event DTO
        let dto = try TypingEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isTyping, true)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.parentId, eventPayload.parentId)
        XCTAssertEqual(event.isThread, true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_stopTypingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userStopTyping,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try TypingEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? TypingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isTyping, false)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.parentId, nil)
        XCTAssertEqual(event.isThread, false)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

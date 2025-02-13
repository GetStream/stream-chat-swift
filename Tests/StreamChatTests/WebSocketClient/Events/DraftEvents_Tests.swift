//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftEvents_Tests: XCTestCase {
    let draftId: String = "draft-123"
    let cid = ChannelId(type: .messaging, id: "general")
    let threadId: MessageId = "thread-123"
    
    var eventDecoder: EventDecoder!
    
    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }
    
    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }
    
    // MARK: - DraftUpdatedEvent Tests
    
    func test_draftUpdatedEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "DraftUpdated")
        let event = try eventDecoder.decode(from: json) as? DraftUpdatedEventDTO
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.draft.message.id, draftId)
        XCTAssertEqual(event?.draft.message.text, "Test draft message")
        XCTAssertEqual(event?.createdAt.description, "2024-02-11 15:42:21 +0000")
    }
    
    func test_draftUpdatedEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "DraftUpdated")
        let event = try eventDecoder.decode(from: json) as? DraftUpdatedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Save required data
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
        _ = try session.saveMessage(payload: .dummy(messageId: draftId, authorUserId: "test-user"), for: cid, cache: nil)
        
        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? DraftUpdatedEvent)
        XCTAssertEqual(domainEvent.cid, cid)
        XCTAssertEqual(domainEvent.draftMessage.id, draftId)
    }
    
    func test_draftUpdatedEvent_toDomainEvent_returnsNilWhenMissingData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "DraftUpdated")
        let event = try eventDecoder.decode(from: json) as? DraftUpdatedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Don't save any data to test nil case
        XCTAssertNil(event?.toDomainEvent(session: session))
    }
    
    // MARK: - DraftDeletedEvent Tests
    
    func test_draftDeletedEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "DraftDeleted")
        let event = try eventDecoder.decode(from: json) as? DraftDeletedEventDTO
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.draft.parentId, threadId)
        XCTAssertEqual(event?.createdAt.description, "2024-02-11 15:42:21 +0000")
    }
    
    func test_draftDeletedEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "DraftDeleted")
        let event = try eventDecoder.decode(from: json) as? DraftDeletedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? DraftDeletedEvent)
        XCTAssertEqual(domainEvent.cid, cid)
        XCTAssertEqual(domainEvent.threadId, threadId)
    }
}

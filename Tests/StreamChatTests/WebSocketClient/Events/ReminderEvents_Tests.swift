//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReminderEvents_Tests: XCTestCase {
    private let messageId = "477172a9-a59b-48dc-94a3-9aec4dc181bb"
    private let cid = ChannelId(type: .messaging, id: "!members-vhPyEGDAjFA4JyC7fxDg3LsMFLGqKhXOKqZM-Y681_E")
    
    var eventDecoder: EventDecoder!
    
    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }
    
    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }
    
    // MARK: - ReminderCreatedEvent Tests
    
    func test_reminderCreatedEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderCreated")
        let event = try eventDecoder.decode(from: json) as? ReminderCreatedEventDTO
        
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.messageId, "f7af18f2-0a46-431d-8901-19c105de7f0a")
        XCTAssertEqual(event?.reminder.channelCid, cid)
        XCTAssertNil(event?.reminder.remindAt)
        XCTAssertEqual(event?.createdAt.description, "2025-03-20 15:50:09 +0000")
    }
    
    func test_reminderCreatedEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderCreated")
        let event = try eventDecoder.decode(from: json) as? ReminderCreatedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Save required data
        let channelId = event?.reminder.channelCid ?? cid
        let messageId = event?.messageId ?? "test-message-id"
        _ = try session.saveChannel(payload: .dummy(cid: channelId), query: nil, cache: nil)
        _ = try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: "test-user"), for: channelId, cache: nil)
        
        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReminderCreatedEvent)
        XCTAssertEqual(domainEvent.messageId, "f7af18f2-0a46-431d-8901-19c105de7f0a")
        XCTAssertEqual(domainEvent.reminder.id, "f7af18f2-0a46-431d-8901-19c105de7f0a")
        XCTAssertEqual(domainEvent.reminder.channel.cid, channelId)
    }
    
    func test_reminderCreatedEvent_toDomainEvent_whenRemoveChannelOnly_shouldSaveChannelFromEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderCreated")
        let event = try eventDecoder.decode(from: json) as? ReminderCreatedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReminderCreatedEvent)
        XCTAssertEqual(domainEvent.messageId, event?.messageId)
        XCTAssertEqual(domainEvent.reminder.id, event?.messageId)
        XCTAssertEqual(domainEvent.reminder.channel.name, event?.reminder.channel?.name)
    }
    
    // MARK: - ReminderUpdatedEvent Tests
    
    func test_reminderUpdatedEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderUpdated")
        let event = try eventDecoder.decode(from: json) as? ReminderUpdatedEventDTO
        
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reminder.channelCid, cid)
        XCTAssertEqual(event?.reminder.remindAt?.description, "2025-03-20 15:50:58 +0000")
        XCTAssertEqual(event?.createdAt.description, "2025-03-20 15:48:58 +0000")
    }
    
    func test_reminderUpdatedEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderUpdated")
        let event = try eventDecoder.decode(from: json) as? ReminderUpdatedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Save required data
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
        _ = try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: "test-user"), for: cid, cache: nil)
        
        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReminderUpdatedEvent)
        XCTAssertEqual(domainEvent.messageId, messageId)
        XCTAssertEqual(domainEvent.reminder.id, messageId)
        XCTAssertEqual(domainEvent.reminder.channel.cid, cid)
        XCTAssertEqual(domainEvent.reminder.remindAt?.description, "2025-03-20 15:50:58 +0000")
    }
    
    func test_reminderUpdatedEvent_toDomainEvent_returnsNilWhenMissingData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderUpdated")
        let event = try eventDecoder.decode(from: json) as? ReminderUpdatedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Don't save any data to test nil case
        XCTAssertNil(event?.toDomainEvent(session: session))
    }
    
    // MARK: - ReminderDeletedEvent Tests
    
    func test_reminderDeletedEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderDeleted")
        let event = try eventDecoder.decode(from: json) as? ReminderDeletedEventDTO
        
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reminder.channelCid, cid)
        XCTAssertEqual(event?.reminder.remindAt?.description, "2025-03-20 15:50:58 +0000")
        XCTAssertEqual(event?.createdAt.description, "2025-03-20 15:49:25 +0000")
    }
    
    func test_reminderDeletedEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderDeleted")
        let event = try eventDecoder.decode(from: json) as? ReminderDeletedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Save required data
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
        _ = try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: "test-user"), for: cid, cache: nil)
        
        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReminderDeletedEvent)
        XCTAssertEqual(domainEvent.messageId, messageId)
        XCTAssertEqual(domainEvent.reminder.id, messageId)
        XCTAssertEqual(domainEvent.reminder.channel.cid, cid)
        XCTAssertEqual(domainEvent.reminder.remindAt?.description, "2025-03-20 15:50:58 +0000")
    }
    
    func test_reminderDeletedEvent_toDomainEvent_returnsNilWhenMissingData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderDeleted")
        let event = try eventDecoder.decode(from: json) as? ReminderDeletedEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Don't save any data to test nil case
        XCTAssertNil(event?.toDomainEvent(session: session))
    }
    
    // MARK: - ReminderDueEvent Tests
    
    func test_reminderDueEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderDue")
        let event = try eventDecoder.decode(from: json) as? ReminderDueNotificationEventDTO
        
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reminder.channelCid, cid)
        XCTAssertEqual(event?.reminder.remindAt?.description, "2025-03-20 15:50:58 +0000")
        XCTAssertEqual(event?.createdAt.description, "2025-03-20 15:48:58 +0000")
    }
    
    func test_reminderDueEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderDue")
        let event = try eventDecoder.decode(from: json) as? ReminderDueNotificationEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Save required data
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
        _ = try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: "test-user"), for: cid, cache: nil)
        
        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReminderDueEvent)
        XCTAssertEqual(domainEvent.messageId, messageId)
        XCTAssertEqual(domainEvent.reminder.id, messageId)
        XCTAssertEqual(domainEvent.reminder.channel.cid, cid)
        XCTAssertEqual(domainEvent.reminder.remindAt?.description, "2025-03-20 15:50:58 +0000")
    }
    
    func test_reminderDueEvent_toDomainEvent_returnsNilWhenMissingData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReminderDue")
        let event = try eventDecoder.decode(from: json) as? ReminderDueNotificationEventDTO
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        
        // Don't save any data to test nil case
        XCTAssertNil(event?.toDomainEvent(session: session))
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReminderUpdaterMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: ReminderUpdaterMiddleware!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy(kind: .inMemory)
        middleware = ReminderUpdaterMiddleware()
    }
    
    override func tearDown() {
        middleware = nil
        database = nil
        super.tearDown()
    }
    
    func test_reminderCreatedEvent_savesReminder() throws {
        // Setup
        let messageId = "test-message-id"
        let cid = ChannelId(type: .messaging, id: "test-channel")
        let reminderPayload = ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let eventPayload = EventPayload(
            eventType: .messageReminderCreated,
            createdAt: Date(),
            messageId: messageId,
            reminder: reminderPayload
        )
        
        let event = try ReminderCreatedEventDTO(from: eventPayload)

        // Save required data for reminder to reference
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: "test-user"),
                for: cid,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: nil
            )
        }
        
        // Execute
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert
        let reminder = database.viewContext.message(id: messageId)?.reminder
        XCTAssertNotNil(reminder, "Reminder should be saved")
        XCTAssertEqual(reminder?.id, messageId, "Reminder ID should match message ID")
    }
    
    func test_reminderUpdatedEvent_updatesReminder() throws {
        // Setup
        let messageId = "test-message-id"
        let cid = ChannelId(type: .messaging, id: "test-channel")
        let initialDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let updatedDate = Date() // now
        
        // First create the reminder
        let initialReminderPayload = ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: initialDate,
            createdAt: initialDate,
            updatedAt: initialDate
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: "test-user"),
                for: cid,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: nil
            )
            try session.saveReminder(payload: initialReminderPayload, cache: nil)
        }
        
        // Create update payload
        let updatedReminderPayload = ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: updatedDate,
            createdAt: initialDate,
            updatedAt: updatedDate
        )
        
        let eventPayload = EventPayload(
            eventType: .messageReminderUpdated,
            createdAt: Date(),
            messageId: messageId,
            reminder: updatedReminderPayload
        )
        
        let event = try ReminderUpdatedEventDTO(from: eventPayload)

        // Execute
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert
        let reminder = database.viewContext.message(id: messageId)?.reminder
        XCTAssertNotNil(reminder, "Reminder should exist")
        XCTAssertNearlySameDate(reminder?.remindAt?.bridgeDate, updatedDate)
    }
    
    func test_reminderDueNotificationEvent_updatesReminder() throws {
        // Setup
        let messageId = "test-message-id"
        let cid = ChannelId(type: .messaging, id: "test-channel")
        let initialDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        // First create the reminder
        let initialReminderPayload = ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: initialDate,
            createdAt: initialDate,
            updatedAt: initialDate
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: "test-user"),
                for: cid,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: nil
            )
            try session.saveReminder(payload: initialReminderPayload, cache: nil)
        }
        
        // Create due notification payload (same as the original in this case)
        let eventPayload = EventPayload(
            eventType: .messageReminderDue,
            createdAt: Date(),
            messageId: messageId,
            reminder: initialReminderPayload
        )
        
        let event = try ReminderDueNotificationEventDTO(from: eventPayload)

        // Execute
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert
        let reminder = database.viewContext.message(id: messageId)?.reminder
        XCTAssertNotNil(reminder, "Reminder should still exist after due notification")
    }
    
    func test_reminderDeletedEvent_deletesReminder() throws {
        // Setup
        let messageId = "test-message-id"
        let cid = ChannelId(type: .messaging, id: "test-channel")
        
        // First create the reminder
        let reminderPayload = ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: "test-user"),
                for: cid,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: nil
            )
            try session.saveReminder(payload: reminderPayload, cache: nil)
        }
        
        // Verify reminder exists
        XCTAssertNotNil(database.viewContext.message(id: messageId)?.reminder, "Reminder should exist before deletion")

        // Create delete event payload
        let eventPayload = EventPayload(
            eventType: .messageReminderDeleted,
            createdAt: Date(),
            messageId: messageId,
            reminder: reminderPayload
        )
        
        let event = try ReminderDeletedEventDTO(from: eventPayload)
        
        // Execute
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert
        XCTAssertNil(database.viewContext.message(id: messageId)?.reminder, "Reminder should be deleted")
    }
}

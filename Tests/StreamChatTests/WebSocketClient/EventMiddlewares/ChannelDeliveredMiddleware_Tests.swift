//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelDeliveredMiddleware_Tests: XCTestCase {
    var middleware: ChannelDeliveredMiddleware!
    var deliveryTracker: ChannelDeliveryTracker_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy(kind: .inMemory)
        deliveryTracker = ChannelDeliveryTracker_Mock()
        middleware = ChannelDeliveredMiddleware(deliveryTracker: deliveryTracker)
    }

    override func tearDown() {
        deliveryTracker.cleanUp()
        AssertAsync.canBeReleased(&middleware)
        AssertAsync.canBeReleased(&deliveryTracker)
        AssertAsync.canBeReleased(&database)
        
        middleware = nil
        deliveryTracker = nil
        database = nil
        
        super.tearDown()
    }

    // MARK: - MessageNewEvent Tests

    func test_handleMessageNewEvent_whenCanMarkMessageAsDelivered_callsSubmitForDelivery() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        let currentUserId = UserId.unique
        let authorUserId = UserId.unique

        // Set up valid scenario in database
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId))
            try session.saveChannel(payload: self.dummyPayload(with: channelId, channelConfig: .mock(deliveredEventsEnabled: true)))

            // Save message from another user
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: authorUserId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }

        let messageNewEvent = try createMessageNewEvent(
            channelId: channelId,
            messageId: messageId,
            authorUserId: authorUserId
        )

        // WHEN
        _ = middleware.handle(event: messageNewEvent, session: database.viewContext)

        // THEN
        XCTAssertEqual(deliveryTracker.submitForDelivery_callCount, 1)
        XCTAssertEqual(deliveryTracker.submitForDelivery_channelId, channelId)
        XCTAssertEqual(deliveryTracker.submitForDelivery_messageId, messageId)
    }

    func test_handleMessageNewEvent_whenCantMarkMessageAsDelivered_doesNotCallSubmitForDelivery() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        let currentUserId = UserId.unique
        let authorUserId = UserId.unique
        
        // Set up database with channel that has delivered events disabled
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId))
            var channelPayload = self.dummyPayload(with: channelId, channelConfig: .mock(deliveredEventsEnabled: false))
            try session.saveChannel(payload: channelPayload)
            
            // Save the message
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: authorUserId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }
        
        let messageNewEvent = try createMessageNewEvent(
            channelId: channelId,
            messageId: messageId,
            authorUserId: authorUserId
        )
        
        // WHEN
        _ = middleware.handle(event: messageNewEvent, session: database.viewContext)
        
        // THEN
        XCTAssertEqual(deliveryTracker.submitForDelivery_callCount, 0)
    }

    // MARK: - NotificationMarkReadEvent Tests

    func test_handleNotificationMarkReadEvent_callsCancel() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let markReadEvent = try createNotificationMarkReadEvent(channelId: channelId)

        // WHEN
        _ = middleware.handle(event: markReadEvent, session: database.viewContext)

        // THEN
        XCTAssertEqual(deliveryTracker.cancel_callCount, 1)
        XCTAssertEqual(deliveryTracker.cancel_channelId, channelId)
    }

    // MARK: - MessageDeliveredEvent Tests

    func test_handleMessageDeliveredEvent_updatesChannelReadData() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        let userId = UserId.unique
        let deliveredAt = Date()
        
        // Create channel and user in database
        let channelDTO = ChannelDTO.loadOrCreate(cid: channelId, context: database.viewContext, cache: nil)
        
        let messageDeliveredEvent = try createMessageDeliveredEvent(
            channelId: channelId,
            userId: userId,
            messageId: messageId,
            deliveredAt: deliveredAt
        )

        // WHEN
        _ = middleware.handle(event: messageDeliveredEvent, session: database.viewContext)

        // THEN
        // Channel read should be created/updated
        let channelRead = channelDTO.reads.first { $0.user.id == userId }
        XCTAssertNotNil(channelRead)
        XCTAssertEqual(channelRead?.lastDeliveredMessageId, messageId)
        XCTAssertNotNil(channelRead?.lastDeliveredAt)
    }
    
    func test_handleMessageDeliveredEvent_createsNewChannelReadIfNotExists() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        let userId = UserId.unique
        let deliveredAt = Date()
        
        // Create channel and user in database
        let channelDTO = ChannelDTO.loadOrCreate(cid: channelId, context: database.viewContext, cache: nil)
        
        // Ensure no existing channel read
        XCTAssertTrue(channelDTO.reads.isEmpty)
        
        let messageDeliveredEvent = try createMessageDeliveredEvent(
            channelId: channelId,
            userId: userId,
            messageId: messageId,
            deliveredAt: deliveredAt
        )

        // WHEN
        _ = middleware.handle(event: messageDeliveredEvent, session: database.viewContext)

        // THEN
        // New channel read should be created
        XCTAssertEqual(channelDTO.reads.count, 1)
        let channelRead = channelDTO.reads.first!
        XCTAssertEqual(channelRead.user.id, userId)
        XCTAssertEqual(channelRead.lastDeliveredMessageId, messageId)
        XCTAssertNotNil(channelRead.lastDeliveredAt)
    }

    func test_handleMessageDeliveredEvent_whenFromCurrentUser_cancelsDelivery() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        let userId = UserId.unique
        let deliveredAt = Date()

        // Create channel and user in database
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: userId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }

        let messageDeliveredEvent = try createMessageDeliveredEvent(
            channelId: channelId,
            userId: userId,
            messageId: messageId,
            deliveredAt: deliveredAt
        )

        // WHEN
        _ = middleware.handle(event: messageDeliveredEvent, session: database.viewContext)

        // THEN
        XCTAssertEqual(deliveryTracker.cancel_callCount, 1)
    }

    // MARK: - Helper Methods

    private func dummyPayload(with channelId: ChannelId) -> ChannelPayload {
        ChannelPayload.dummy(channel: .dummy(cid: channelId))
    }

    private func createMessageNewEvent(channelId: ChannelId, messageId: MessageId, authorUserId: UserId? = nil) throws -> MessageNewEventDTO {
        let userId = authorUserId ?? UserId.unique
        let user = UserPayload.dummy(userId: userId)
        let message = MessagePayload.dummy(messageId: messageId, authorUserId: user.id)
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        
        let eventPayload = EventPayload(
            eventType: .messageNew,
            cid: channelId,
            user: user,
            channel: channel,
            message: message,
            createdAt: message.createdAt
        )
        
        return try MessageNewEventDTO(from: eventPayload)
    }

    private func createNotificationMarkReadEvent(channelId: ChannelId) throws -> NotificationMarkReadEventDTO {
        let user = UserPayload.dummy(userId: .unique)
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            cid: channelId,
            user: user,
            channel: channel,
            unreadCount: .init(channels: 0, messages: 0, threads: 0),
            createdAt: .unique(after: Date())
        )
        
        return try NotificationMarkReadEventDTO(from: eventPayload)
    }
    
    private func createMessageDeliveredEvent(
        channelId: ChannelId,
        userId: UserId,
        messageId: MessageId,
        deliveredAt: Date
    ) throws -> MessageDeliveredEventDTO {
        let user = UserPayload.dummy(userId: userId)
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        
        let eventPayload = EventPayload(
            eventType: .messageDelivered,
            cid: channelId,
            user: user,
            channel: channel,
            createdAt: .unique(after: Date()),
            lastDeliveredAt: deliveredAt,
            lastDeliveredMessageId: messageId
        )
        
        return try MessageDeliveredEventDTO(from: eventPayload)
    }
}

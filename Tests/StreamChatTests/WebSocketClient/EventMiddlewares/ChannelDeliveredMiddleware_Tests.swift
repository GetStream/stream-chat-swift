//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelDeliveredMiddleware_Tests: XCTestCase {
    var middleware: ChannelDeliveredMiddleware!
    var deliveryTracker: ChannelDeliveryTracker_Mock!
    var deliveryCriteriaValidator: MessageDeliveryCriteriaValidator_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy(kind: .inMemory)
        deliveryTracker = ChannelDeliveryTracker_Mock()
        deliveryCriteriaValidator = MessageDeliveryCriteriaValidator_Mock()
        middleware = ChannelDeliveredMiddleware(
            deliveryTracker: deliveryTracker,
            deliveryCriteriaValidator: deliveryCriteriaValidator
        )
    }

    override func tearDown() {
        deliveryTracker.cleanUp()
        AssertAsync.canBeReleased(&middleware)
        AssertAsync.canBeReleased(&deliveryTracker)
        AssertAsync.canBeReleased(&deliveryCriteriaValidator)
        AssertAsync.canBeReleased(&database)
        
        middleware = nil
        deliveryTracker = nil
        deliveryCriteriaValidator = nil
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

        // Set up minimal database state
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId))
            try session.saveChannel(payload: self.dummyPayload(with: channelId))
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: authorUserId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }
        
        // Configure mock to allow delivery
        deliveryCriteriaValidator.canMarkMessageAsDeliveredClosure = { _, _, _ in true }

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
        
        // Set up minimal database state
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId))
            try session.saveChannel(payload: self.dummyPayload(with: channelId))
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: authorUserId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }
        
        // Configure mock to reject delivery
        deliveryCriteriaValidator.canMarkMessageAsDeliveredClosure = { _, _, _ in false }
        
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

    private func dummyPayload(with channelId: ChannelId) -> ChannelStateResponseFields {
        ChannelStateResponseFields.dummy(channel: .dummy(cid: channelId))
    }

    private func createMessageNewEvent(channelId: ChannelId, messageId: MessageId, authorUserId: UserId? = nil) throws -> MessageNewEventDTO {
        let userId = authorUserId ?? UserId.unique
        let user = UserResponse.dummy(userId: userId)
        let message = MessageResponse.dummy(messageId: messageId, authorUserId: user.id)
        let channel = ChannelResponse.dummy(cid: channelId)

        return MessageNewEventDTO(
            channel: channel,
            cid: channelId.rawValue,
            createdAt: message.createdAt,
            custom: [:],
            message: message,
            messageId: messageId,
            user: user.asUserResponseCommonFields(),
            watcherCount: 0
        )
    }

    private func createNotificationMarkReadEvent(channelId: ChannelId) throws -> NotificationMarkReadEventDTO {
        let user = UserResponse.dummy(userId: .unique)
        let channel = ChannelResponse.dummy(cid: channelId)

        return NotificationMarkReadEventDTO(
            channel: channel,
            cid: channelId.rawValue,
            createdAt: .unique(after: Date()),
            custom: [:],
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: user.asUserResponseCommonFields()
        )
    }

    private func createMessageDeliveredEvent(
        channelId: ChannelId,
        userId: UserId,
        messageId: MessageId,
        deliveredAt: Date
    ) throws -> MessageDeliveredEventDTO {
        let user = UserResponse.dummy(userId: userId)
        let channel = ChannelResponse.dummy(cid: channelId)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return MessageDeliveredEventDTO(
            channel: channel,
            cid: channelId.rawValue,
            createdAt: .unique(after: Date()),
            custom: [:],
            lastDeliveredAt: formatter.string(from: deliveredAt),
            lastDeliveredMessageId: messageId,
            user: user.asUserResponseCommonFields()
        )
    }
}

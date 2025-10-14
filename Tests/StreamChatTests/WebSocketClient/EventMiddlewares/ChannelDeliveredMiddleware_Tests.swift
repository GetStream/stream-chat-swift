//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelDeliveredMiddleware_Tests: XCTestCase {
    var middleware: ChannelDeliveredMiddleware!
    var currentUserUpdater: CurrentUserUpdater_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy(kind: .inMemory)
        currentUserUpdater = CurrentUserUpdater_Mock(database: database, apiClient: APIClient_Spy())
        
        middleware = ChannelDeliveredMiddleware(
            currentUserUpdater: currentUserUpdater,
            throttler: Throttler(interval: 0.0),
            queue: .main
        )
    }

    override func tearDown() {
        currentUserUpdater.cleanUp()
        AssertAsync.canBeReleased(&middleware)
        AssertAsync.canBeReleased(&currentUserUpdater)
        AssertAsync.canBeReleased(&database)
        
        middleware = nil
        currentUserUpdater = nil
        database = nil
        
        super.tearDown()
    }

    // MARK: - MessageNewEvent Tests

    func test_handleMessageNewEvent_triggersMarkChannelsDelivered() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        let messageNewEvent = try createMessageNewEvent(channelId: channelId, messageId: messageId)

        let exp = expectation(description: "should complete")
        currentUserUpdater.markChannelsDelivered_completion = { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // WHEN
        _ = middleware.handle(event: messageNewEvent, session: database.viewContext)
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let deliveredMessages = currentUserUpdater.markChannelsDelivered_deliveredMessages
        XCTAssertEqual(deliveredMessages?.count, 1)
        XCTAssertEqual(deliveredMessages?.first?.channelId, channelId)
        XCTAssertEqual(deliveredMessages?.first?.messageId, messageId)
        XCTAssertEqual(currentUserUpdater.markChannelsDelivered_callCount, 1)
    }

    func test_handleMessageNewEvent_whenMultipleChannels_triggersOnlyOneDeliveredCall() throws {
        // GIVEN
        let channelId1 = ChannelId.unique
        let channelId2 = ChannelId.unique
        let messageId1 = MessageId.unique
        let messageId2 = MessageId.unique
        
        let event1 = try createMessageNewEvent(channelId: channelId1, messageId: messageId1)
        let event2 = try createMessageNewEvent(channelId: channelId2, messageId: messageId2)

        let exp = expectation(description: "should complete")
        currentUserUpdater.markChannelsDelivered_completion = { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // WHEN
        _ = middleware.handle(event: event1, session: database.viewContext)
        _ = middleware.handle(event: event2, session: database.viewContext)
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let deliveredMessages = currentUserUpdater.markChannelsDelivered_deliveredMessages
        XCTAssertEqual(deliveredMessages?.count, 2)
        
        let channelIds = Set(deliveredMessages?.map(\.channelId) ?? [])
        XCTAssertTrue(channelIds.contains(channelId1))
        XCTAssertTrue(channelIds.contains(channelId2))
        XCTAssertEqual(currentUserUpdater.markChannelsDelivered_callCount, 1)
    }
    
    func test_handleMessageNewEvent_directlyUpdatesPendingChannels() throws {
        // GIVEN
        let channelId1 = ChannelId.unique
        let channelId2 = ChannelId.unique
        let messageId1 = MessageId.unique
        let messageId2 = MessageId.unique
        
        let event1 = try createMessageNewEvent(channelId: channelId1, messageId: messageId1)
        let event2 = try createMessageNewEvent(channelId: channelId2, messageId: messageId2)

        // WHEN
        _ = middleware.handle(event: event1, session: database.viewContext)
        _ = middleware.handle(event: event2, session: database.viewContext)

        // THEN
        // Wait for async operations to complete
        AssertAsync.willBeTrue(middleware.pendingDeliveredChannels[channelId1] == messageId1, timeout: 1.0)
        AssertAsync.willBeTrue(middleware.pendingDeliveredChannels[channelId2] == messageId2, timeout: 1.0)
        AssertAsync.willBeTrue(middleware.pendingDeliveredChannels.count == 2, timeout: 1.0)
    }

    func test_handleMessageNewEvent_updatesExistingChannelWithLatestMessage() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let firstMessageId = MessageId.unique
        let secondMessageId = MessageId.unique
        
        let firstEvent = try createMessageNewEvent(channelId: channelId, messageId: firstMessageId)
        let secondEvent = try createMessageNewEvent(channelId: channelId, messageId: secondMessageId)

        let exp = expectation(description: "should complete")
        currentUserUpdater.markChannelsDelivered_completion = { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // WHEN
        _ = middleware.handle(event: firstEvent, session: database.viewContext)
        _ = middleware.handle(event: secondEvent, session: database.viewContext)
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let deliveredMessages = currentUserUpdater.markChannelsDelivered_deliveredMessages
        XCTAssertEqual(deliveredMessages?.count, 1)
        XCTAssertEqual(deliveredMessages?.first?.channelId, channelId)
        XCTAssertEqual(deliveredMessages?.first?.messageId, secondMessageId)
        XCTAssertEqual(currentUserUpdater.markChannelsDelivered_callCount, 1)
    }

    // MARK: - NotificationMarkReadEvent Tests

    func test_handleNotificationMarkReadEvent_removesChannelFromPendingList() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        
        // Add channel to pending list first
        middleware.pendingDeliveredChannels = [
            channelId: messageId
        ]
        
        let markReadEvent = try createNotificationMarkReadEvent(channelId: channelId)
        _ = middleware.handle(event: markReadEvent, session: database.viewContext)

        // THEN
        AssertAsync.willBeTrue(middleware.pendingDeliveredChannels.isEmpty)
    }

    // MARK: - Helper Methods

    private func createMessageNewEvent(channelId: ChannelId, messageId: MessageId) throws -> MessageNewEventDTO {
        let user = UserPayload.dummy(userId: .unique)
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
}

//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelDeliveryTracker_Tests: XCTestCase {
    var tracker: ChannelDeliveryTracker!
    var currentUserUpdater: CurrentUserUpdater_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy(kind: .inMemory)
        currentUserUpdater = CurrentUserUpdater_Mock(database: database, apiClient: APIClient_Spy())
        
        tracker = ChannelDeliveryTracker(
            currentUserUpdater: currentUserUpdater,
            throttler: Throttler(interval: 0.0),
            queue: .main
        )
    }

    override func tearDown() {
        currentUserUpdater.cleanUp()
        AssertAsync.canBeReleased(&tracker)
        AssertAsync.canBeReleased(&currentUserUpdater)
        AssertAsync.canBeReleased(&database)
        
        tracker = nil
        currentUserUpdater = nil
        database = nil
        
        super.tearDown()
    }

    // MARK: - submitForDelivery Tests

    func test_submitForDelivery_triggersMarkChannelsDelivered() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique

        let exp = expectation(description: "should complete")
        currentUserUpdater.markChannelsDelivered_completion = { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // WHEN
        tracker.submitForDelivery(channelId: channelId, messageId: messageId)
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let deliveredMessages = currentUserUpdater.markChannelsDelivered_deliveredMessages
        XCTAssertEqual(deliveredMessages?.count, 1)
        XCTAssertEqual(deliveredMessages?.first?.channelId, channelId)
        XCTAssertEqual(deliveredMessages?.first?.messageId, messageId)
        XCTAssertEqual(currentUserUpdater.markChannelsDelivered_callCount, 1)
    }

    func test_submitForDelivery_whenMultipleChannels_triggersOnlyOneDeliveredCall() throws {
        // GIVEN
        let channelId1 = ChannelId.unique
        let channelId2 = ChannelId.unique
        let messageId1 = MessageId.unique
        let messageId2 = MessageId.unique

        let exp = expectation(description: "should complete")
        currentUserUpdater.markChannelsDelivered_completion = { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // WHEN
        tracker.submitForDelivery(channelId: channelId1, messageId: messageId1)
        tracker.submitForDelivery(channelId: channelId2, messageId: messageId2)
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let deliveredMessages = currentUserUpdater.markChannelsDelivered_deliveredMessages
        XCTAssertEqual(deliveredMessages?.count, 2)
        
        let channelIds = Set(deliveredMessages?.map(\.channelId) ?? [])
        XCTAssertTrue(channelIds.contains(channelId1))
        XCTAssertTrue(channelIds.contains(channelId2))
        XCTAssertEqual(currentUserUpdater.markChannelsDelivered_callCount, 1)
    }
    
    func test_submitForDelivery_directlyUpdatesPendingChannels() throws {
        // GIVEN
        let channelId1 = ChannelId.unique
        let channelId2 = ChannelId.unique
        let messageId1 = MessageId.unique
        let messageId2 = MessageId.unique

        // WHEN
        tracker.submitForDelivery(channelId: channelId1, messageId: messageId1)
        tracker.submitForDelivery(channelId: channelId2, messageId: messageId2)

        // THEN
        // Wait for async operations to complete
        AssertAsync.willBeTrue(tracker.pendingDeliveredChannels[channelId1] == messageId1, timeout: 1.0)
        AssertAsync.willBeTrue(tracker.pendingDeliveredChannels[channelId2] == messageId2, timeout: 1.0)
        AssertAsync.willBeTrue(tracker.pendingDeliveredChannels.count == 2, timeout: 1.0)
    }

    func test_submitForDelivery_updatesExistingChannelWithLatestMessage() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let firstMessageId = MessageId.unique
        let secondMessageId = MessageId.unique

        let exp = expectation(description: "should complete")
        currentUserUpdater.markChannelsDelivered_completion = { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // WHEN
        tracker.submitForDelivery(channelId: channelId, messageId: firstMessageId)
        tracker.submitForDelivery(channelId: channelId, messageId: secondMessageId)
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let deliveredMessages = currentUserUpdater.markChannelsDelivered_deliveredMessages
        XCTAssertEqual(deliveredMessages?.count, 1)
        XCTAssertEqual(deliveredMessages?.first?.channelId, channelId)
        XCTAssertEqual(deliveredMessages?.first?.messageId, secondMessageId)
        XCTAssertEqual(currentUserUpdater.markChannelsDelivered_callCount, 1)
    }

    // MARK: - cancel Tests

    func test_cancel_removesChannelFromPendingList() throws {
        // GIVEN
        let channelId = ChannelId.unique
        let messageId = MessageId.unique
        
        // Add channel to pending list first
        tracker.submitForDelivery(channelId: channelId, messageId: messageId)
        
        // Wait for async operation to complete
        AssertAsync.willBeTrue(tracker.pendingDeliveredChannels[channelId] == messageId, timeout: 1.0)

        // WHEN
        tracker.cancel(channelId: channelId)

        // THEN
        AssertAsync.willBeTrue(tracker.pendingDeliveredChannels.isEmpty)
    }

    func test_pendingDeliveredChannels_isEmptyWhenNoPendingDeliveries() throws {
        // WHEN
        let pendingDeliveries = tracker.pendingDeliveredChannels

        // THEN
        XCTAssertTrue(pendingDeliveries.isEmpty)
    }
}

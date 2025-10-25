//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageDeliveryCriteriaValidator_Tests: XCTestCase {
    var validator: MessageDeliveryCriteriaValidator!
    
    override func setUp() {
        super.setUp()
        validator = MessageDeliveryCriteriaValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    // MARK: - Test Helpers
    
    /// Creates a valid scenario where all criteria are met for message delivery.
    /// Individual tests can override specific parameters to test failure cases.
    private func makeValidDeliveryScenario(
        currentUserId: UserId = .unique,
        messageId: MessageId = .unique,
        messageAuthorId: UserId = .unique,
        messageCreatedAt: Date = Date(timeIntervalSince1970: 2000),
        messageText: String = "Test message",
        messageParentId: MessageId? = nil,
        messageShowReplyInChannel: Bool = false,
        messageIsShadowed: Bool = false,
        messageIsSentByCurrentUser: Bool = false,
        deliveryEventsEnabled: Bool = true,
        channelIsMuted: Bool = false,
        channelIsHidden: Bool = false,
        deliveryReceiptsEnabled: Bool = true,
        mutedUsers: [ChatUser] = [],
        lastReadAt: Date = Date(timeIntervalSince1970: 1000),
        lastDeliveredAt: Date? = Date(timeIntervalSince1970: 1500),
        includeReadState: Bool = true
    ) -> (message: ChatMessage, currentUser: CurrentChatUser, channel: ChatChannel) {
        let messageAuthor = ChatUser.mock(id: messageAuthorId)
        
        let currentUser = CurrentChatUser.mock(
            currentUserId: currentUserId,
            mutedUsers: Set(mutedUsers),
            privacySettings: .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true),
                deliveryReceipts: .init(enabled: deliveryReceiptsEnabled)
            )
        )
        
        let message = ChatMessage.mock(
            id: messageId,
            cid: .unique,
            text: messageText,
            author: messageAuthor,
            createdAt: messageCreatedAt,
            parentMessageId: messageParentId,
            showReplyInChannel: messageShowReplyInChannel,
            isShadowed: messageIsShadowed,
            isSentByCurrentUser: messageIsSentByCurrentUser
        )
        
        var reads: [ChatChannelRead] = []
        if includeReadState {
            let readState = ChatChannelRead(
                lastReadAt: lastReadAt,
                lastReadMessageId: .unique,
                unreadMessagesCount: 0,
                user: .mock(id: currentUserId),
                lastDeliveredAt: lastDeliveredAt,
                lastDeliveredMessageId: lastDeliveredAt != nil ? .unique : nil
            )
            reads = [readState]
        }
        
        let channel = ChatChannel.mock(
            cid: .unique,
            isHidden: channelIsHidden,
            config: .mock(deliveryEventsEnabled: deliveryEventsEnabled),
            reads: reads,
            muteDetails: channelIsMuted ? .init(createdAt: .unique, updatedAt: nil, expiresAt: nil) : nil
        )
        
        return (message, currentUser, channel)
    }
    
    // MARK: - Channel Configuration Tests
    
    func test_canMarkMessageAsDelivered_whenChannelCannotBeMarkedAsDelivered_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            deliveryEventsEnabled: false
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenChannelIsMuted_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            channelIsMuted: true
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenChannelIsHidden_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            channelIsHidden: true
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    // MARK: - Privacy Settings Tests
    
    func test_canMarkMessageAsDelivered_whenDeliveryReceiptsDisabled_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            deliveryReceiptsEnabled: false
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    // MARK: - Message Thread Tests
    
    func test_canMarkMessageAsDelivered_whenMessageIsThreadReplyNotShownInChannel_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            messageParentId: .unique,
            messageShowReplyInChannel: false
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageIsThreadReplyShownInChannel_canReturnTrue() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            messageParentId: .unique,
            messageShowReplyInChannel: true
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertTrue(result)
    }
    
    // MARK: - Message Author Tests
    
    func test_canMarkMessageAsDelivered_whenMessageFromCurrentUser_returnsFalse() {
        // GIVEN
        let currentUserId = UserId.unique
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            currentUserId: currentUserId,
            messageAuthorId: currentUserId,
            messageIsSentByCurrentUser: true
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageIsShadowed_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            messageIsShadowed: true
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageAuthorIsMuted_returnsFalse() {
        // GIVEN
        let mutedUserId = UserId.unique
        let mutedUser = ChatUser.mock(id: mutedUserId)
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            messageAuthorId: mutedUserId,
            mutedUsers: [mutedUser]
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    // MARK: - Read State Tests
    
    func test_canMarkMessageAsDelivered_whenNoReadState_returnsTrue() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            includeReadState: false
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertTrue(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageNotAfterLastReadAt_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            messageCreatedAt: Date(timeIntervalSince1970: 1000),
            lastReadAt: Date(timeIntervalSince1970: 2000)
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    // MARK: - Delivery State Tests
    
    func test_canMarkMessageAsDelivered_whenMessageAlreadyDelivered_returnsFalse() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            messageCreatedAt: Date(timeIntervalSince1970: 2000),
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastDeliveredAt: Date(timeIntervalSince1970: 2500)
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenAllConditionsMet_returnsTrue() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario()
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertTrue(result)
    }
    
    func test_canMarkMessageAsDelivered_whenNoDeliveredStateYet_returnsTrue() {
        // GIVEN
        let (message, currentUser, channel) = makeValidDeliveryScenario(
            lastDeliveredAt: nil
        )
        
        // WHEN
        let result = validator.canMarkMessageAsDelivered(message, for: currentUser, in: channel)
        
        // THEN
        XCTAssertTrue(result)
    }
}

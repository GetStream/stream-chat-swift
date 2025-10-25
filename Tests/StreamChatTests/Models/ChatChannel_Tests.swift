//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatChannel_Tests: XCTestCase {
    func test_isUnread_whenUnreadCountIsNotZero_returnsTrue() {
        let counts: [ChannelUnreadCount] = [
            .init(
                messages: 1,
                mentions: 0
            ),
            .init(
                messages: 0,
                mentions: 1
            )
        ]

        for unreadCount in counts {
            let channel: ChatChannel = .mock(
                cid: .unique,
                unreadCount: unreadCount
            )

            XCTAssertTrue(channel.isUnread)
        }
    }

    func test_isUnread_whenUnreadCountIsZero_returnsFalse() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            unreadCount: .noUnread
        )

        XCTAssertFalse(channel.isUnread)
    }

    // MARK: Capabilities

    func test_ownCapabilities() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            ownCapabilities: [.banChannelMembers, .createCall, .deleteAnyMessage],
            unreadCount: .noUnread
        )

        XCTAssertTrue(channel.ownCapabilities.contains(.banChannelMembers))
        XCTAssertTrue(channel.ownCapabilities.contains(.createCall))
        XCTAssertTrue(channel.ownCapabilities.contains(.deleteAnyMessage))
        XCTAssertFalse(channel.ownCapabilities.contains(.freezeChannel))
    }

    func test_canBanChannelMembers() throws {
        let channel = setupChannel(withCapabilities: [.banChannelMembers])
        XCTAssertEqual(channel.canBanChannelMembers, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canBanChannelMembers, false)
    }

    func test_canReceiveConnectEvents() throws {
        let channel = setupChannel(withCapabilities: [.connectEvents])
        XCTAssertEqual(channel.canReceiveConnectEvents, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canReceiveConnectEvents, false)
    }

    func test_canDeleteAnyMessage() throws {
        let channel = setupChannel(withCapabilities: [.deleteAnyMessage])
        XCTAssertEqual(channel.canDeleteAnyMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canDeleteAnyMessage, false)
    }

    func test_canDeleteChannel() throws {
        let channel = setupChannel(withCapabilities: [.deleteChannel])
        XCTAssertEqual(channel.canDeleteChannel, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canDeleteChannel, false)
    }

    func test_canDeleteOwnMessage() throws {
        let channel = setupChannel(withCapabilities: [.deleteOwnMessage])
        XCTAssertEqual(channel.canDeleteOwnMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canDeleteOwnMessage, false)
    }

    func test_canFlagMessage() throws {
        let channel = setupChannel(withCapabilities: [.flagMessage])
        XCTAssertEqual(channel.canFlagMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canFlagMessage, false)
    }

    func test_canFreezeChannel() throws {
        let channel = setupChannel(withCapabilities: [.freezeChannel])
        XCTAssertEqual(channel.canFreezeChannel, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canFreezeChannel, false)
    }

    func test_canLeaveChannel() throws {
        let channel = setupChannel(withCapabilities: [.leaveChannel])
        XCTAssertEqual(channel.canLeaveChannel, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canLeaveChannel, false)
    }

    func test_canJoinChannel() throws {
        let channel = setupChannel(withCapabilities: [.joinChannel])
        XCTAssertEqual(channel.canJoinChannel, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canJoinChannel, false)
    }

    func test_canMuteChannel() throws {
        let channel = setupChannel(withCapabilities: [.muteChannel])
        XCTAssertEqual(channel.canMuteChannel, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canMuteChannel, false)
    }

    func test_canPinMessage() throws {
        let channel = setupChannel(withCapabilities: [.pinMessage])
        XCTAssertEqual(channel.canPinMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canPinMessage, false)
    }

    func test_canQuoteMessage() throws {
        let channel = setupChannel(withCapabilities: [.quoteMessage])
        XCTAssertEqual(channel.canQuoteMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canQuoteMessage, false)
    }

    func test_canReceiveReadEvents() throws {
        let channel = setupChannel(withCapabilities: [.readEvents])
        XCTAssertEqual(channel.canReceiveReadEvents, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canReceiveReadEvents, false)
    }

    func test_canSearchMessages() throws {
        let channel = setupChannel(withCapabilities: [.searchMessages])
        XCTAssertEqual(channel.canSearchMessages, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSearchMessages, false)
    }

    func test_canSendCustomEvents() throws {
        let channel = setupChannel(withCapabilities: [.sendCustomEvents])
        XCTAssertEqual(channel.canSendCustomEvents, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendCustomEvents, false)
    }

    func test_canSendLinks() throws {
        let channel = setupChannel(withCapabilities: [.sendLinks])
        XCTAssertEqual(channel.canSendLinks, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendLinks, false)
    }

    func test_canSendMessage() throws {
        let channel = setupChannel(withCapabilities: [.sendMessage])
        XCTAssertEqual(channel.canSendMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendMessage, false)
    }

    func test_canSendReaction() throws {
        let channel = setupChannel(withCapabilities: [.sendReaction])
        XCTAssertEqual(channel.canSendReaction, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendReaction, false)
    }

    func test_canSendReply() throws {
        let channel = setupChannel(withCapabilities: [.sendReply])
        XCTAssertEqual(channel.canSendReply, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendReply, false)
    }

    func test_canSetChannelCooldown() throws {
        let channel = setupChannel(withCapabilities: [.setChannelCooldown])
        XCTAssertEqual(channel.canSetChannelCooldown, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSetChannelCooldown, false)
    }

    func test_canSendTypingEvents() throws {
        let channel = setupChannel(withCapabilities: [.sendTypingEvents])
        XCTAssertEqual(channel.canSendTypingEvents, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendTypingEvents, false)
    }

    func test_canUpdateAnyMessage() throws {
        let channel = setupChannel(withCapabilities: [.updateAnyMessage])
        XCTAssertEqual(channel.canUpdateAnyMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canUpdateAnyMessage, false)
    }

    func test_canUpdateChannel() throws {
        let channel = setupChannel(withCapabilities: [.updateChannel])
        XCTAssertEqual(channel.canUpdateChannel, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canUpdateChannel, false)
    }

    func test_canUpdateChannelMembers() throws {
        let channel = setupChannel(withCapabilities: [.updateChannelMembers])
        XCTAssertEqual(channel.canUpdateChannelMembers, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canUpdateChannelMembers, false)
    }

    func test_canUpdateOwnMessage() throws {
        let channel = setupChannel(withCapabilities: [.updateOwnMessage])
        XCTAssertEqual(channel.canUpdateOwnMessage, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canUpdateOwnMessage, false)
    }

    func test_canUploadFile() throws {
        let channel = setupChannel(withCapabilities: [.uploadFile])
        XCTAssertEqual(channel.canUploadFile, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canUploadFile, false)
    }

    func test_canJoinCall() throws {
        let channel = setupChannel(withCapabilities: [.joinCall])
        XCTAssertEqual(channel.canJoinCall, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canJoinCall, false)
    }

    func test_canCreateCall() throws {
        let channel = setupChannel(withCapabilities: [.createCall])
        XCTAssertEqual(channel.canCreateCall, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canCreateCall, false)
    }

    func test_isSlowMode() throws {
        let channel = setupChannel(withCapabilities: [.slowMode])
        XCTAssertEqual(channel.isSlowMode, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.isSlowMode, false)
    }

    func test_canSendPoll() throws {
        let channel = setupChannel(withCapabilities: [.sendPoll])
        XCTAssertEqual(channel.canSendPoll, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canSendPoll, false)
    }

    func test_canCastPollVote() throws {
        let channel = setupChannel(withCapabilities: [.castPollVote])
        XCTAssertEqual(channel.canCastPollVote, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canCastPollVote, false)
    }

    func test_canShareLocation() throws {
        let channel = setupChannel(withCapabilities: [.shareLocation])
        XCTAssertEqual(channel.canShareLocation, true)

        let channelWithoutCapability = setupChannel(withCapabilities: [])
        XCTAssertEqual(channelWithoutCapability.canShareLocation, false)
    }

    func test_lastReadMessageId_readsDontContainUser() {
        let userId: UserId = "current"
        let channel = ChatChannel.mock(cid: .unique, reads: [
            .init(lastReadAt: Date(), lastReadMessageId: .unique, unreadMessagesCount: 3, user: .mock(id: "other"))
        ])

        XCTAssertNil(channel.lastReadMessageId(userId: userId))
    }

    func test_lastReadMessageId_userReadDoesNotHaveLastRead() {
        let userId: UserId = "current"
        let channel = ChatChannel.mock(cid: .unique, reads: [
            .init(lastReadAt: Date(), lastReadMessageId: nil, unreadMessagesCount: 3, user: .mock(id: userId)),
            .init(lastReadAt: Date(), lastReadMessageId: .unique, unreadMessagesCount: 3, user: .mock(id: "other"))
        ])

        XCTAssertNil(channel.lastReadMessageId(userId: userId))
    }

    func test_lastReadMessageId_userReadHasLastRead() {
        let userId: UserId = "current"
        let lastReadId = MessageId.unique
        let channel = ChatChannel.mock(cid: .unique, reads: [
            .init(lastReadAt: Date(), lastReadMessageId: lastReadId, unreadMessagesCount: 3, user: .mock(id: userId)),
            .init(lastReadAt: Date(), lastReadMessageId: .unique, unreadMessagesCount: 3, user: .mock(id: "other"))
        ])

        XCTAssertEqual(channel.lastReadMessageId(userId: userId), lastReadId)
    }

    func test_replacing() {
        let originalChannel = ChatChannel.mock(
            cid: .unique,
            name: "Original Name",
            imageURL: URL(string: "http://original.com/image.jpg"),
            extraData: ["original": .string("data")]
        )
        
        // Test replacing all fields
        let allFieldsReplaced = originalChannel.replacing(
            name: "New Name",
            imageURL: URL(string: "http://new.com/image.jpg"),
            extraData: ["new": .string("data")]
        )
        
        // Verify replaced fields
        XCTAssertEqual(allFieldsReplaced.name, "New Name")
        XCTAssertEqual(allFieldsReplaced.imageURL?.absoluteString, "http://new.com/image.jpg")
        XCTAssertEqual(allFieldsReplaced.extraData["new"]?.stringValue, "data")
        
        // Verify other fields remain unchanged
        XCTAssertEqual(allFieldsReplaced.cid, originalChannel.cid)
        XCTAssertEqual(allFieldsReplaced.lastMessageAt, originalChannel.lastMessageAt)
        XCTAssertEqual(allFieldsReplaced.createdAt, originalChannel.createdAt)
        
        // Test replacing some fields while erasing others
        let partialReplacement = originalChannel.replacing(
            name: "New Name",
            imageURL: nil,
            extraData: nil
        )
        
        XCTAssertEqual(partialReplacement.name, "New Name")
        XCTAssertEqual(partialReplacement.imageURL, nil)
        XCTAssertEqual(partialReplacement.extraData, [:])
    }
    
    // MARK: - Changing Method Tests
    
    func test_changing_withNoParameters_returnsUnchangedChannel() {
        // Given
        let originalChannel = createComprehensiveChannel()
        
        // When
        let unchangedChannel = originalChannel.changing()
        
        // Then - All properties should remain the same
        XCTAssertEqual(unchangedChannel.cid, originalChannel.cid)
        XCTAssertEqual(unchangedChannel.name, originalChannel.name)
        XCTAssertEqual(unchangedChannel.imageURL, originalChannel.imageURL)
        XCTAssertEqual(unchangedChannel.lastMessageAt, originalChannel.lastMessageAt)
        XCTAssertEqual(unchangedChannel.createdAt, originalChannel.createdAt)
        XCTAssertEqual(unchangedChannel.updatedAt, originalChannel.updatedAt)
        XCTAssertEqual(unchangedChannel.deletedAt, originalChannel.deletedAt)
        XCTAssertEqual(unchangedChannel.truncatedAt, originalChannel.truncatedAt)
        XCTAssertEqual(unchangedChannel.isHidden, originalChannel.isHidden)
        XCTAssertEqual(unchangedChannel.createdBy?.id, originalChannel.createdBy?.id)
        XCTAssertEqual(unchangedChannel.ownCapabilities, originalChannel.ownCapabilities)
        XCTAssertEqual(unchangedChannel.isFrozen, originalChannel.isFrozen)
        XCTAssertEqual(unchangedChannel.isDisabled, originalChannel.isDisabled)
        XCTAssertEqual(unchangedChannel.isBlocked, originalChannel.isBlocked)
        XCTAssertEqual(unchangedChannel.lastActiveMembers.count, originalChannel.lastActiveMembers.count)
        XCTAssertEqual(unchangedChannel.membership?.id, originalChannel.membership?.id)
        XCTAssertEqual(unchangedChannel.memberCount, originalChannel.memberCount)
        XCTAssertEqual(unchangedChannel.lastActiveWatchers.count, originalChannel.lastActiveWatchers.count)
        XCTAssertEqual(unchangedChannel.watcherCount, originalChannel.watcherCount)
        XCTAssertEqual(unchangedChannel.reads.count, originalChannel.reads.count)
        XCTAssertEqual(unchangedChannel.team, originalChannel.team)
        XCTAssertEqual(unchangedChannel.cooldownDuration, originalChannel.cooldownDuration)
        XCTAssertEqual(unchangedChannel.extraData, originalChannel.extraData)
    }

    func test_changing_withAllParameters_updatesAllSpecifiedProperties() {
        // Given
        let originalChannel = createComprehensiveChannel()
        
        // Create new values for all parameters
        let newName = "Completely Updated Name"
        let newImageURL = URL(string: "https://example.com/completely-new.jpg")
        let newLastMessageAt = Date().addingTimeInterval(-500)
        let newCreatedAt = Date().addingTimeInterval(-345_600) // 4 days ago
        let newDeletedAt = Date().addingTimeInterval(-100)
        let newUpdatedAt = Date().addingTimeInterval(-200)
        let newTruncatedAt = Date().addingTimeInterval(-300)
        let newIsHidden = !originalChannel.isHidden
        let newCreatedBy = ChatUser.mock(id: .unique, name: "Completely New Creator")
        let newConfig = ChannelConfig.mock()
        let newOwnCapabilities: Set<ChannelCapability> = [.sendMessage, .deleteAnyMessage, .updateChannel]
        let newIsFrozen = !originalChannel.isFrozen
        let newIsDisabled = !originalChannel.isDisabled
        let newIsBlocked = !originalChannel.isBlocked
        let newMember = ChatChannelMember.dummy(id: .unique)
        let newMembers = [newMember]
        let newMembership = newMember
        let newMemberCount = 99
        let newWatcher = ChatUser.mock(id: .unique, name: "All New Watcher")
        let newWatchers = [newWatcher]
        let newWatcherCount = 33
        let newTeam = "all-new-team"
        let newCooldownDuration = 180
        let newExtraData: [String: RawJSON] = ["completelyNew": .string("allNewValue")]
        
        // When
        let completelyUpdatedChannel = originalChannel.changing(
            name: newName,
            imageURL: newImageURL,
            lastMessageAt: newLastMessageAt,
            createdAt: newCreatedAt,
            deletedAt: newDeletedAt,
            updatedAt: newUpdatedAt,
            truncatedAt: newTruncatedAt,
            isHidden: newIsHidden,
            createdBy: newCreatedBy,
            config: newConfig,
            ownCapabilities: newOwnCapabilities,
            isFrozen: newIsFrozen,
            isDisabled: newIsDisabled,
            isBlocked: newIsBlocked,
            members: newMembers,
            membership: newMembership,
            memberCount: newMemberCount,
            watchers: newWatchers,
            watcherCount: newWatcherCount,
            team: newTeam,
            cooldownDuration: newCooldownDuration,
            extraData: newExtraData
        )
        
        // Then - All properties should be updated
        XCTAssertEqual(completelyUpdatedChannel.name, newName)
        XCTAssertEqual(completelyUpdatedChannel.imageURL, newImageURL)
        XCTAssertEqual(completelyUpdatedChannel.lastMessageAt, newLastMessageAt)
        XCTAssertEqual(completelyUpdatedChannel.createdAt, newCreatedAt)
        XCTAssertEqual(completelyUpdatedChannel.deletedAt, newDeletedAt)
        XCTAssertEqual(completelyUpdatedChannel.updatedAt, newUpdatedAt)
        XCTAssertEqual(completelyUpdatedChannel.truncatedAt, newTruncatedAt)
        XCTAssertEqual(completelyUpdatedChannel.isHidden, newIsHidden)
        XCTAssertEqual(completelyUpdatedChannel.createdBy?.id, newCreatedBy.id)
        XCTAssertEqual(completelyUpdatedChannel.ownCapabilities, newOwnCapabilities)
        XCTAssertEqual(completelyUpdatedChannel.isFrozen, newIsFrozen)
        XCTAssertEqual(completelyUpdatedChannel.isDisabled, newIsDisabled)
        XCTAssertEqual(completelyUpdatedChannel.isBlocked, newIsBlocked)
        XCTAssertEqual(completelyUpdatedChannel.lastActiveMembers.count, 1)
        XCTAssertEqual(completelyUpdatedChannel.lastActiveMembers.first?.id, newMember.id)
        XCTAssertEqual(completelyUpdatedChannel.membership?.id, newMembership.id)
        XCTAssertEqual(completelyUpdatedChannel.memberCount, newMemberCount)
        XCTAssertEqual(completelyUpdatedChannel.lastActiveWatchers.count, 1)
        XCTAssertEqual(completelyUpdatedChannel.lastActiveWatchers.first?.id, newWatcher.id)
        XCTAssertEqual(completelyUpdatedChannel.watcherCount, newWatcherCount)
        XCTAssertEqual(completelyUpdatedChannel.team, newTeam)
        XCTAssertEqual(completelyUpdatedChannel.cooldownDuration, newCooldownDuration)
        XCTAssertEqual(completelyUpdatedChannel.extraData, newExtraData)
        
        // Verify immutable properties remain the same
        XCTAssertEqual(completelyUpdatedChannel.cid, originalChannel.cid)
    }
    
    // MARK: - canMarkMessageAsDelivered Tests
    
    func test_canMarkMessageAsDelivered_whenChannelCannotBeMarkedAsDelivered_returnsFalse() {
        // GIVEN
        let currentUser = CurrentChatUser.mock(currentUserId: .unique)
        let message = ChatMessage.mock(id: .unique, cid: .unique, text: "Test")
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: false)
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenChannelIsMuted_returnsFalse() {
        // GIVEN
        let currentUser = CurrentChatUser.mock(currentUserId: .unique)
        let message = ChatMessage.mock(id: .unique, cid: .unique, text: "Test", author: .mock(id: .unique))
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            muteDetails: .init(createdAt: .unique, updatedAt: nil, expiresAt: nil)
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenChannelIsHidden_returnsFalse() {
        // GIVEN
        let currentUser = CurrentChatUser.mock(currentUserId: .unique)
        let message = ChatMessage.mock(id: .unique, cid: .unique, text: "Test", author: .mock(id: .unique))
        let channel = ChatChannel.mock(
            cid: .unique,
            isHidden: true,
            config: .mock(deliveryEventsEnabled: true)
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenDeliveryReceiptsDisabled_returnsFalse() {
        // GIVEN
        let currentUser = CurrentChatUser.mock(
            currentUserId: .unique,
            privacySettings: .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true),
                deliveryReceipts: .init(enabled: false)
            )
        )
        let message = ChatMessage.mock(id: .unique, cid: .unique, text: "Test", author: .mock(id: .unique))
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true)
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageIsThreadReplyNotShownInChannel_returnsFalse() {
        // GIVEN
        let currentUser = CurrentChatUser.mock(currentUserId: .unique)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Thread reply",
            author: .mock(id: .unique),
            parentMessageId: .unique,
            showReplyInChannel: false
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUser.id)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageIsThreadReplyShownInChannel_canReturnTrue() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Thread reply shown in channel",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000),
            parentMessageId: .unique,
            showReplyInChannel: true
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertTrue(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageFromCurrentUser_returnsFalse() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "My message",
            author: .mock(id: currentUserId),
            isSentByCurrentUser: true
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageIsShadowed_returnsFalse() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Shadowed message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000),
            isShadowed: true
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageAuthorIsMuted_returnsFalse() {
        // GIVEN
        let currentUserId = UserId.unique
        let mutedUserId = UserId.unique
        let mutedUser = ChatUser.mock(id: mutedUserId)
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId, mutedUsers: [mutedUser])
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Message from muted user",
            author: mutedUser,
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenNoReadState_returnsTrue() {
        // GIVEN
        let currentUser = CurrentChatUser.mock(currentUserId: .unique)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: []
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertTrue(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageNotAfterLastReadAt_returnsFalse() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Old message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 2000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenMessageAlreadyDelivered_returnsFalse() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Already delivered message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId),
            lastDeliveredAt: Date(timeIntervalSince1970: 2500),
            lastDeliveredMessageId: .unique
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertFalse(result)
    }
    
    func test_canMarkMessageAsDelivered_whenAllConditionsMet_returnsTrue() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "New undelivered message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId),
            lastDeliveredAt: Date(timeIntervalSince1970: 1500),
            lastDeliveredMessageId: .unique
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertTrue(result)
    }
    
    func test_canMarkMessageAsDelivered_whenNoDeliveredStateYet_returnsTrue() {
        // GIVEN
        let currentUserId = UserId.unique
        let currentUser = CurrentChatUser.mock(currentUserId: currentUserId)
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "First message to deliver",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: currentUserId)
            // No lastDeliveredAt
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            config: .mock(deliveryEventsEnabled: true),
            reads: [readState]
        )
        
        // WHEN
        let result = channel.canMarkMessageAsDelivered(message, for: currentUser)
        
        // THEN
        XCTAssertTrue(result)
    }

    // MARK: - Reads and DeliveredReads Tests
    
    func test_reads_forMessage_whenNoReads_returnsEmptyArray() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: []
        )
        
        // WHEN
        let result = channel.reads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_reads_forMessage_whenNoReadsAfterMessage_returnsEmptyArray() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000), // Before message
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: .unique)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState]
        )
        
        // WHEN
        let result = channel.reads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_reads_forMessage_whenMessageFromSameUser_returnsEmptyArray() {
        // GIVEN
        let authorId = UserId.unique
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: authorId),
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 2000), // After message
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: authorId) // Same as message author
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState]
        )
        
        // WHEN
        let result = channel.reads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_reads_forMessage_whenValidReads_returnsCorrectReads() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let user1 = ChatUser.mock(id: .unique)
        let user2 = ChatUser.mock(id: .unique)
        let user3 = ChatUser.mock(id: .unique)
        
        let readState1 = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000), // After message
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: user1
        )
        let readState2 = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 1000), // Before message
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: user2
        )
        let readState3 = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 2500), // After message
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: user3
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState1, readState2, readState3]
        )
        
        // WHEN
        let result = channel.reads(for: message)
        
        // THEN
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.user.id == user1.id })
        XCTAssertTrue(result.contains { $0.user.id == user3.id })
        XCTAssertFalse(result.contains { $0.user.id == user2.id })
    }
    
    func test_deliveredReads_forMessage_whenNoReads_returnsEmptyArray() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: []
        )
        
        // WHEN
        let result = channel.deliveredReads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_deliveredReads_forMessage_whenNoDeliveredAfterMessage_returnsEmptyArray() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: .unique),
            lastDeliveredAt: Date(timeIntervalSince1970: 1000), // Before message
            lastDeliveredMessageId: .unique
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState]
        )
        
        // WHEN
        let result = channel.deliveredReads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_deliveredReads_forMessage_whenNoDeliveredState_returnsEmptyArray() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: .unique)
            // No delivered state
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState]
        )
        
        // WHEN
        let result = channel.deliveredReads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_deliveredReads_forMessage_whenMessageFromSameUser_returnsEmptyArray() {
        // GIVEN
        let authorId = UserId.unique
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: authorId),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: authorId), // Same as message author
            lastDeliveredAt: Date(timeIntervalSince1970: 2500), // After message
            lastDeliveredMessageId: .unique
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState]
        )
        
        // WHEN
        let result = channel.deliveredReads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_deliveredReads_forMessage_whenValidDeliveredReads_returnsCorrectReads() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let user1 = ChatUser.mock(id: .unique)
        let user2 = ChatUser.mock(id: .unique)
        let user3 = ChatUser.mock(id: .unique)
        
        let readState1 = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: user1,
            lastDeliveredAt: Date(timeIntervalSince1970: 2500), // After message
            lastDeliveredMessageId: .unique
        )
        let readState2 = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: user2,
            lastDeliveredAt: Date(timeIntervalSince1970: 1000), // Before message
            lastDeliveredMessageId: .unique
        )
        let readState3 = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: user3,
            lastDeliveredAt: Date(timeIntervalSince1970: 2200), // After message
            lastDeliveredMessageId: .unique
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState1, readState2, readState3]
        )
        
        // WHEN
        let result = channel.deliveredReads(for: message)
        
        // THEN
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.user.id == user1.id })
        XCTAssertTrue(result.contains { $0.user.id == user3.id })
        XCTAssertFalse(result.contains { $0.user.id == user2.id })
    }
    
    func test_deliveredReads_forMessage_whenDeliveredAtIsNil_returnsEmptyArray() {
        // GIVEN
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Test message",
            author: .mock(id: .unique),
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let readState = ChatChannelRead(
            lastReadAt: Date(timeIntervalSince1970: 3000),
            lastReadMessageId: .unique,
            unreadMessagesCount: 0,
            user: .mock(id: .unique),
            lastDeliveredAt: nil, // nil delivered time
            lastDeliveredMessageId: .unique
        )
        let channel = ChatChannel.mock(
            cid: .unique,
            reads: [readState]
        )
        
        // WHEN
        let result = channel.deliveredReads(for: message)
        
        // THEN
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Helper Methods

    private func createComprehensiveChannel() -> ChatChannel {
        let createdBy = ChatUser.mock(id: .unique, name: "Original Creator")
        let member = ChatChannelMember.dummy(id: .unique)
        let watcher = ChatUser.mock(id: .unique, name: "Original Watcher")

        return ChatChannel.mock(
            cid: .unique,
            name: "Original Channel",
            imageURL: URL(string: "https://example.com/original.jpg"),
            lastMessageAt: Date().addingTimeInterval(-3600), // 1 hour ago
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            deletedAt: nil,
            isHidden: false,
            createdBy: createdBy,
            config: .mock(),
            ownCapabilities: [.sendMessage, .readEvents],
            isFrozen: false,
            isDisabled: false,
            isBlocked: false,
            lastActiveMembers: [member],
            membership: member,
            lastActiveWatchers: [watcher],
            team: "original-team",
            watcherCount: 5,
            memberCount: 10,
            cooldownDuration: 30,
            extraData: ["originalKey": .string("originalValue")]
        )
    }

    private func setupChannel(withCapabilities capabilities: Set<ChannelCapability>) -> ChatChannel {
        .mock(
            cid: .unique,
            ownCapabilities: capabilities
        )
    }
}

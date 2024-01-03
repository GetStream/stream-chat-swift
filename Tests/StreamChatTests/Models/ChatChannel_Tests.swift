//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    private func setupChannel(withCapabilities capabilities: Set<ChannelCapability>) -> ChatChannel {
        .mock(
            cid: .unique,
            ownCapabilities: capabilities
        )
    }
}

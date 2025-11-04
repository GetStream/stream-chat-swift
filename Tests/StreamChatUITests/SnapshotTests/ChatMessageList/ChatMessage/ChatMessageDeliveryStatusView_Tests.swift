//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatMessageDeliveryStatusView_Tests: XCTestCase {
    // MARK: - Sending

    func test_appearance_whenMesssageInSendingState() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 10
        )

        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: .sending,
            isSentByCurrentUser: true
        )

        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints

        view.content = .init(message: message, channel: channel)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    // MARK: - Sent

    func test_appearance_whenMessageIsSent() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 10
        )

        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints

        view.content = .init(message: message, channel: channel)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    // MARK: - Read

    func test_appearance_whenMessageIsReadInDirectMessagesChannel() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 2
        )

        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints

        view.content = .init(message: message, channel: channel)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageIsReadInGroupChannel() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 10
        )

        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [
                .mock(id: .unique),
                .mock(id: .unique),
                .mock(id: .unique)
            ]
        )

        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints

        view.content = .init(message: message, channel: channel)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    // MARK: - Delivered

    func test_appearance_whenMessageIsDeliveredInDirectMessagesChannel() {
        let messageAuthor: ChatUser = .mock(id: .unique)
        let otherUser: ChatUser = .mock(id: .unique)
        let messageCreatedAt = Date()
        let cid = ChannelId.unique

        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: messageAuthor,
            createdAt: messageCreatedAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let channel: ChatChannel = .mock(
            cid: cid,
            config: .mock(readEventsEnabled: true, deliveryEventsEnabled: true),
            memberCount: 2,
            reads: [
                .mock(
                    lastReadAt: Date.distantPast,
                    lastReadMessageId: nil,
                    unreadMessagesCount: 0,
                    user: otherUser,
                    lastDeliveredAt: messageCreatedAt,
                    lastDeliveredMessageId: message.id
                )
            ]
        )

        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints

        view.content = .init(message: message, channel: channel)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageIsDeliveredInGroupChannel() {
        let messageAuthor: ChatUser = .mock(id: .unique)
        let otherUser: ChatUser = .mock(id: .unique)
        let messageCreatedAt = Date()
        let cid = ChannelId.unique

        let message: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            author: messageAuthor,
            createdAt: messageCreatedAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let channel: ChatChannel = .mock(
            cid: cid,
            config: .mock(readEventsEnabled: true, deliveryEventsEnabled: true),
            memberCount: 10,
            reads: [
                .mock(
                    lastReadAt: Date.distantPast,
                    lastReadMessageId: nil,
                    unreadMessagesCount: 0,
                    user: otherUser,
                    lastDeliveredAt: messageCreatedAt,
                    lastDeliveredMessageId: message.id
                )
            ]
        )

        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints

        view.content = .init(message: message, channel: channel)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelListItemView_Tests: XCTestCase {
    let currentUser: ChatUser = .mock(
        id: "yoda",
        name: "Yoda"
    )
    
    // MARK: - Appearance
    
    func test_emptyState() {
        // Make sure the view is empty if there was content before.
        let view = channelItemView(content: .init(channel: .mock(cid: .unique), currentUserId: .unique))
        view.content = nil
        AssertSnapshot(view)
    }
    
    func test_appearance_pendingPreviewMessageFromCurrentUser_readsEnabled() {
        let pendingSendMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Pending send message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: .pendingSend,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: pendingSendMessage,
                    readEventsEnabled: true
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_pendingPreviewMessageFromCurrentUser_readsDisabled() {
        let pendingSendMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Pending send message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: .pendingSend,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: pendingSendMessage,
                    readEventsEnabled: false
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_sentPreviewMessageFromCurrentUser_readsEnabled() {
        let sentMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Sent message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: nil,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: sentMessage,
                    readEventsEnabled: true
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_sentPreviewMessageFromCurrentUser_readsDisabled() {
        let sentMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Sent message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: nil,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: sentMessage,
                    readEventsEnabled: false
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_readPreviewMessageFromCurrentUser_readsEnabled() {
        let readMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Read message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [
                .mock(id: .unique),
                .mock(id: .unique)
            ]
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: readMessage,
                    readEventsEnabled: true
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_readPreviewMessageFromCurrentUser_readsDisabled() {
        let readMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Read message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [
                .mock(id: .unique),
                .mock(id: .unique)
            ]
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: readMessage,
                    readEventsEnabled: false
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_failedPreviewMessageFromCurrentUser_readsEnabled() {
        let readMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Failed message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: .sendingFailed,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: readMessage,
                    readEventsEnabled: true
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_failedPreviewMessageFromCurrentUser_readsDisabled() {
        let readMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Failed message from current user",
            author: currentUser,
            createdAt: Date(timeIntervalSince1970: 100),
            localState: .sendingFailed,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: readMessage,
                    readEventsEnabled: false
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_readPreviewMessageFromAnotherUser_readEnabled() {
        let readMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Read message from another user",
            author: .mock(id: "another-user", name: "Another user"),
            createdAt: Date(timeIntervalSince1970: 100),
            localState: nil,
            isSentByCurrentUser: false,
            readBy: [
                .mock(id: .unique),
                .mock(id: .unique)
            ]
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: readMessage,
                    readEventsEnabled: true
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_systemPreviewMessage() {
        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Channel truncated",
            type: .system,
            author: .mock(id: "another-user", name: "Another user"),
            createdAt: Date(timeIntervalSince1970: 100),
            localState: nil,
            isSentByCurrentUser: true
        )
        
        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: systemMessage,
                    readEventsEnabled: true
                ),
                currentUserId: currentUser.id
            )
        )
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.bodyBold = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .cyan
        
        let view = channelItemView(
            content: .init(
                channel: channel(readEventsEnabled: true),
                currentUserId: currentUser.id
            ),
            appearance: appearance
        )
        
        AssertSnapshot(view)
    }
        
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelListItemView {
            lazy var footnoteLabel = UILabel()
                .withoutAutoresizingMaskConstraints
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
            
            override func setUpAppearance() {
                super.setUpAppearance()
                titleLabel.textColor = .cyan
                subtitleLabel.textColor = .blue
                
                footnoteLabel.adjustsFontForContentSizeCategory = true
                footnoteLabel.font = .preferredFont(forTextStyle: .caption1)
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                topContainer.addArrangedSubview(timestampLabel)
                bottomContainer.addArrangedSubview(unreadCountView)
                
                addSubview(footnoteLabel)
                footnoteLabel.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor).isActive = true
                footnoteLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 8).isActive = true
                
                avatarView
                    .bottomAnchor
                    .constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -20)
                    .isActive = true
            }
            
            override func updateContent() {
                super.updateContent()
                unreadCountView.content = .mock(messages: 3)
                footnoteLabel.text = appearance.formatters
                    .messageTimestamp
                    .format(content!.channel.createdAt)
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        view.components = .mock
        
        view.content = .init(
            channel: channel(
                previewMessage: .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Hey there",
                    author: currentUser,
                    isSentByCurrentUser: true
                ),
                readEventsEnabled: true
            ),
            currentUserId: currentUser.id
        )
        AssertSnapshot(view)
    }

    func test_textProperties_arePropagated() {
        let itemView = ChatChannelListItemView()
        itemView.content = .init(
            channel: .mock(cid: .unique),
            currentUserId: .unique
        )
        itemView.updateContent()

        XCTAssertEqual(itemView.titleText, itemView.titleLabel.text)
        XCTAssertEqual(itemView.subtitleText, itemView.subtitleLabel.text)
        XCTAssertEqual(itemView.timestampText, itemView.timestampLabel.text)
    }
    
    // MARK: - Title
    
    func test_titleText_isNil_whenChannelIsNil() {
        let itemView = ChatChannelListItemView()
        itemView.content = nil
        itemView.updateContent()
        
        XCTAssertNil(itemView.titleText)
    }
    
    func test_titleText_whenChannelNameIsSet() {
        let userId: UserId = .unique

        let channel: ChatChannel = .mock(
            cid: .unique,
            name: "Channel Name",
            membership: .mock(id: userId)
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(itemView.titleText, channel.name)
    }
    
    // MARK: - Subtitle
    
    func test_subtitleText_isNil_whenChannelIsNil() {
        let itemView = ChatChannelListItemView()
        itemView.content = nil
        
        XCTAssertNil(itemView.subtitleText)
    }
    
    func test_subtitleText_whenOneUserIsTyping() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            currentlyTypingUsers: [
                .mock(
                    id: .unique,
                    name: "Member"
                )
            ]
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            "Member " + L10n.Channel.Item.typingSingular
        )
    }
    
    func test_subtitleText_whenTwoUsersAreTyping() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            currentlyTypingUsers: [
                .mock(
                    id: .unique,
                    name: "MemberOne"
                ),
                .mock(
                    id: .unique,
                    name: "MemberTwo"
                )
            ]
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            "MemberOne, MemberTwo " + L10n.Channel.Item.typingPlural
        )
    }
    
    func test_subtitleText_whenPreviewMessageIsSentByAnotherUserWithName() {
        let authorName = "Author name"
        
        let previewMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Message text",
            author: .mock(
                id: .unique,
                name: authorName
            ),
            isSentByCurrentUser: false
        )
                
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: previewMessage
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            "\(authorName): \(previewMessage.text)"
        )
    }
    
    func test_subtitleText_whenPreviewMessageIsSentByAnotherUserWithoutName() {
        let previewMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Message text",
            author: .mock(
                id: "user-id",
                name: nil
            ),
            isSentByCurrentUser: false
        )
                
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: previewMessage
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            "\(previewMessage.author.id): \(previewMessage.text)"
        )
    }
    
    func test_subtitleText_whenPreviewMessageIsSentByCurrentUser() {
        let ownMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hey there",
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: ownMessage,
                    readEventsEnabled: true
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertEqual(itemView.subtitleText, "\(L10n.you): \(ownMessage.text)")
    }
    
    func test_subtitleText_whenPreviewMessageIsSystem() {
        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Channel is truncated",
            type: .system,
            author: .mock(id: .unique)
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: systemMessage,
                    readEventsEnabled: true
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertEqual(itemView.subtitleText, systemMessage.text)
    }
    
    func test_subtitleText_whenNoPreviewMessage() {
        let channel: ChatChannel = .mock(cid: .unique)
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            L10n.Channel.Item.emptyMessages
        )
    }
    
    // MARK: - Timestamp
    
    func test_timestampText_isNil_whenPreviewMessageIsNil() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: nil
        )
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertNil(itemView.timestampText)
    }
    
    func test_timestampText_whenPreviewMessageExists() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                createdAt: Date(timeIntervalSince1970: 1)
            )
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.timestampText,
            "12:00 AM"
        )
    }
    
    // MARK: - Delivery status
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageIsNil() {
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: nil,
                    readEventsEnabled: true
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertNil(itemView.previewMessageDeliveryStatus)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageIsFromAnotherUser() {
        let messageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: false
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: messageFromAnotherUser,
                    readEventsEnabled: true
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertNil(itemView.previewMessageDeliveryStatus)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageFromCurrentUserIsFailed() {
        let messageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: .sendingFailed,
            isSentByCurrentUser: true
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: messageFromAnotherUser,
                    readEventsEnabled: false
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertEqual(itemView.previewMessageDeliveryStatus, .failed)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageFromCurrentUserIsPending() {
        let ownMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: .pendingSend,
            isSentByCurrentUser: true
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: ownMessage,
                    readEventsEnabled: false
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertEqual(itemView.previewMessageDeliveryStatus, .pending)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageFromCurrentUserIsSentAndEnabledReads() {
        let ownSentMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: ownSentMessage,
                    readEventsEnabled: true
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertEqual(itemView.previewMessageDeliveryStatus, .sent)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageFromCurrentUserIsSentAndDisabledReads() {
        let ownSentMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: ownSentMessage,
                    readEventsEnabled: false
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertNil(itemView.previewMessageDeliveryStatus)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageFromCurrentUserIsReadAndEnabledReads() {
        let ownReadMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: ownReadMessage,
                    readEventsEnabled: true
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertEqual(itemView.previewMessageDeliveryStatus, .read)
    }
    
    func test_previewMessageDeliveryStatus_whenPreviewMessageFromCurrentUserIsReadAndDisabledReads() {
        let ownReadMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )
        
        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: ownReadMessage,
                    readEventsEnabled: false
                ),
                currentUserId: .unique
            )
        )
        
        XCTAssertNil(itemView.previewMessageDeliveryStatus)
    }
    
    // MARK: - Helpers
    
    private func channelItemView(
        content: ChatChannelListItemView.Content?,
        components: Components = .mock,
        appearance: Appearance = .default
    ) -> ChatChannelListItemView {
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        view.components = components
        view.appearance = appearance
        view.content = content
        view.addSizeConstraints()
        return view
    }
    
    private func channel(
        previewMessage: ChatMessage? = nil,
        readEventsEnabled: Bool
    ) -> ChatChannel {
        .mock(
            cid: previewMessage?.cid ?? .unique,
            name: "Channel 1",
            imageURL: TestImages.yoda.url,
            createdAt: Date(timeIntervalSince1970: 1),
            config: .mock(readEventsEnabled: readEventsEnabled),
            previewMessage: previewMessage
        )
    }
}

private extension ChatChannelListItemView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 400)
        ])
    }
}

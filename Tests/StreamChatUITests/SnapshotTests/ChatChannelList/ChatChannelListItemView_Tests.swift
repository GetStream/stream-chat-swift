//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelListItemView_Tests: XCTestCase {
    var content: ChatChannelListItemView.Content!
    
    override func setUp() {
        super.setUp()
        content = .init(
            channel: ChatChannel.mock(
                cid: .unique,
                name: "Channel 1",
                imageURL: TestImages.yoda.url,
                lastMessageAt: .init(timeIntervalSince1970: 1_611_951_526_000)
            ),
            currentUserId: .unique
        )
    }
    
    func test_emptyState() {
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        // Make sure the view is empty if there was content before.
        view.content = content
        view.content = nil
        view.addSizeConstraints()
        view.components = .mock
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = content
        view.components = .mock
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.bodyBold = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .cyan
        
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        
        view.appearance = appearance
        view.addSizeConstraints()
        view.components = .mock
        
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
                    .format(content!.channel.lastMessageAt!)
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        view.components = .mock
        
        view.content = content
        AssertSnapshot(view)
    }

    func test_textProperties_arePropagated() {
        let itemView = ChatChannelListItemView()
        itemView.content = content
        itemView.updateContent()

        XCTAssertEqual(itemView.titleText, itemView.titleLabel.text)
        XCTAssertEqual(itemView.subtitleText, itemView.subtitleLabel.text)
        XCTAssertEqual(itemView.timestampText, itemView.timestampLabel.text)
    }
    
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
    
    func test_subtitleText_whenLatestMessageExists() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            latestMessages: [
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Message text",
                    author: .mock(
                        id: .unique,
                        name: "Author name"
                    )
                )
            ]
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            "Author name: Message text"
        )
    }
    
    func test_subtitleText_whenLatestMessageExistsAndAuthorNameDoesNotExist() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            latestMessages: [
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Message text",
                    author: .mock(
                        id: "author-id",
                        name: nil
                    )
                )
            ]
        )
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            "author-id: Message text"
        )
    }
    
    func test_subtitleText_whenNoLatestMessages() {
        let channel: ChatChannel = .mock(cid: .unique)
        
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.subtitleText,
            L10n.Channel.Item.emptyMessages
        )
    }
    
    func test_timestampText_isNil_whenLastMessageAtIsNil() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            lastMessageAt: nil
        )
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertNil(itemView.timestampText)
    }
    
    func test_timestampText_whenLastMessageAtExists() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            lastMessageAt: Date(timeIntervalSince1970: 1)
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
}

private extension ChatChannelListItemView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 400)
        ])
    }
}

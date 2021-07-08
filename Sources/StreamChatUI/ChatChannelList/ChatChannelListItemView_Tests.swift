//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelListItemView_Tests: XCTestCase {
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
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = content
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.bodyBold = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .cyan
        
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        
        view.appearance = appearance
        view.addSizeConstraints()
        
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
                footnoteLabel.text = dateFormatter.string(from: content!.channel.lastMessageAt!)
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        
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

        var components = Components()
        components.channelNamer = { namerChannel, namerUserId in
            XCTAssertEqual(namerChannel, channel)
            XCTAssertEqual(namerUserId, userId)
            return namerChannel.name
        }
        itemView.components = components
        
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let itemView = ChatChannelListItemView()
        itemView.dateFormatter = dateFormatter
        itemView.content = .init(channel: channel, currentUserId: nil)
        
        XCTAssertEqual(
            itemView.timestampText,
            "1970-01-01 00:00:01"
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

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
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
            text: "Pending send message",
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
        view.updateContent()

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_pendingPreviewMessageFromCurrentUser_readsDisabled() {
        let pendingSendMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Pending send message",
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

        AssertSnapshot(view, variants: [.defaultLight])
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

    func test_appearance_audioPreviewMessage() throws {
        let message: ChatMessage = try mockAudioMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_audioPreviewMessage_whenTextIsEmpty() throws {
        let message: ChatMessage = try mockAudioMessage(
            text: "",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_audioPreviewMessage_whenSentByCurrentUser() throws {
        let message: ChatMessage = try mockAudioMessage(
            text: "Example message",
            isSentByCurrentUser: true
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_audioPreviewMessage_whenMultipleMembers() throws {
        let message: ChatMessage = try mockAudioMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 4
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_imagePreviewMessage() throws {
        let message: ChatMessage = try mockImageMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_imagePreviewMessage_whenTextIsEmpty() throws {
        let message: ChatMessage = try mockImageMessage(
            text: "",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_imagePreviewMessage_whenSentByCurrentUser() throws {
        let message: ChatMessage = try mockImageMessage(
            text: "Example message",
            isSentByCurrentUser: true
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_imagePreviewMessage_whenMultipleMembers() throws {
        let message: ChatMessage = try mockImageMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 4
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_videoPreviewMessage() throws {
        let message: ChatMessage = try mockVideoMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_videoPreviewMessage_whenTextIsEmpty() throws {
        let message: ChatMessage = try mockVideoMessage(
            text: "",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_videoPreviewMessage_whenSentByCurrentUser() throws {
        let message: ChatMessage = try mockVideoMessage(
            text: "Example message",
            isSentByCurrentUser: true
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_videoPreviewMessage_whenMultipleMembers() throws {
        let message: ChatMessage = try mockVideoMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 4
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_filePreviewMessage() throws {
        let message: ChatMessage = try mockFileMessage(
            title: "File.pdf",
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_filePreviewMessage_whenTitleIsNil() throws {
        let message: ChatMessage = try mockFileMessage(
            title: nil,
            text: "Example Message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_filePreviewMessage_whenSentByCurrentUser() throws {
        let message: ChatMessage = try mockFileMessage(
            title: "File.pdf",
            text: "Example message",
            isSentByCurrentUser: true
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_filePreviewMessage_whenMultipleMembers() throws {
        let message: ChatMessage = try mockFileMessage(
            title: "File.pdf",
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 4
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_giphyPreviewMessage() throws {
        let message: ChatMessage = try mockGiphyMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_giphyPreviewMessage_whenSentByCurrentUser() throws {
        let message: ChatMessage = try mockGiphyMessage(
            text: "Example message",
            isSentByCurrentUser: true
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_giphyPreviewMessage_whenMultipleMembers() throws {
        let message: ChatMessage = try mockGiphyMessage(
            text: "Example message",
            isSentByCurrentUser: false
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 4
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_searchedMessage() {
        let searchedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "May the force be with you",
            type: .system,
            author: .mock(id: .unique, name: "Yoda", imageURL: .localYodaImage),
            createdAt: Date(timeIntervalSince1970: 100)
        )

        let view = channelItemView(
            content: .init(
                channel: .mock(
                    cid: .unique,
                    name: "Star Wars",
                    unreadCount: .mock(messages: 10) // Should not display unreadCounts
                ),
                currentUserId: currentUser.id,
                searchResult: .init(text: "Dummy", message: searchedMessage)
            )
        )

        let viewWithoutChannelName = channelItemView(
            content: .init(
                channel: .mock(cid: .unique, name: nil),
                currentUserId: currentUser.id,
                searchResult: .init(text: "Dummy", message: searchedMessage)
            )
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
        AssertSnapshot(viewWithoutChannelName, variants: [.defaultLight], suffix: "without-channel-name")
    }

    func test_appearance_translatedMessage() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: .mock(id: .unique, name: "Vader", language: .english),
            createdAt: Date(timeIntervalSince1970: 100),
            translations: [.portuguese: "Olá"]
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: false,
                    membership: .mock(id: .unique, language: .portuguese)
                ),
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_translatedMessage_whenHasAttachment() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: .mock(id: .unique, name: "Vader", language: .english),
            createdAt: Date(timeIntervalSince1970: 100),
            translations: [.portuguese: "Olá"],
            attachments: [
                .dummy(
                    type: .image,
                    payload: try JSONEncoder().encode(ImageAttachmentPayload(
                        title: nil,
                        imageRemoteURL: .localYodaImage
                    )
                    )
                )
            ]
        )

        let view = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: false,
                    membership: .mock(id: .unique, language: .portuguese)
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
        view.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()

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

    func test_appearance_previewMessageIsVoiceRecording() throws {
        let previewMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            attachments: [
                .dummy(
                    type: .voiceRecording,
                    payload: try JSONEncoder().encode(VoiceRecordingAttachmentPayload(
                        title: nil,
                        voiceRecordingRemoteURL: .unique(),
                        file: .init(type: .aac, size: 120, mimeType: nil),
                        duration: nil,
                        waveformData: nil,
                        extraData: nil
                    ))
                )
            ]
        )

        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: previewMessage
        )

        let view = channelItemView(
            content: .init(channel: channel, currentUserId: currentUser.id)
        )

        AssertSnapshot(view)
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

    func test_titleText_whenSearchingMessage() {
        let userId: UserId = .unique

        let channel: ChatChannel = .mock(
            cid: .unique,
            name: "Star Wars",
            membership: .mock(id: userId)
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(
            channel: channel,
            currentUserId: nil,
            searchResult: .init(text: "Dummy", message: .mock(author: .mock(id: .unique, name: "Yoda")))
        )

        XCTAssertEqual(itemView.titleText, "Yoda in Star Wars")
    }

    func test_titleText_whenSearchingMessage_whenNoChannelName() {
        let userId: UserId = .unique

        let channel: ChatChannel = .mock(
            cid: .unique,
            name: nil,
            membership: .mock(id: userId)
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(
            channel: channel,
            currentUserId: nil,
            searchResult: .init(text: "Dummy", message: .mock(author: .mock(id: .unique, name: "Yoda")))
        )

        XCTAssertEqual(itemView.titleText, "Yoda")
    }

    func test_titleText_whenSearchingMessage_whenChannelNameIsEmpty() {
        let userId: UserId = .unique

        let channel: ChatChannel = .mock(
            cid: .unique,
            name: "",
            membership: .mock(id: userId)
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(
            channel: channel,
            currentUserId: nil,
            searchResult: .init(text: "Dummy", message: .mock(author: .mock(id: .unique, name: "Yoda")))
        )

        XCTAssertEqual(itemView.titleText, "Yoda")
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

    func test_subtitleText_whenPreviewMessageIsSentByCurrentUser_andChannelMemberCountIs2() {
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
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: .unique
            )
        )

        XCTAssertEqual(itemView.subtitleText, "\(L10n.you): \(ownMessage.text)")
    }

    func test_subtitleText_whenPreviewMessageIsSentByAnothertUser_andChannelMemberCountIs2() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hey there",
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        let itemView = channelItemView(
            content: .init(
                channel: channel(
                    previewMessage: message,
                    readEventsEnabled: true,
                    memberCount: 2
                ),
                currentUserId: .unique
            )
        )

        XCTAssertEqual(itemView.subtitleText, "\(message.text)")
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

    func test_subtitleText_whenPreviewMessageIsAVoiceRecording() throws {
        let previewMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            attachments: [
                .dummy(
                    type: .voiceRecording,
                    payload: try JSONEncoder().encode(VoiceRecordingAttachmentPayload(
                        title: nil,
                        voiceRecordingRemoteURL: .unique(),
                        file: .init(type: .aac, size: 120, mimeType: nil),
                        duration: nil,
                        waveformData: nil,
                        extraData: nil
                    ))
                )
            ]
        )

        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: previewMessage
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)

        XCTAssertEqual("Voice message", itemView.subtitleText)
        XCTAssertFalse(itemView.subtitleImageView.isHidden)
    }

    func test_subtitleText_whenSearchingMessage() {
        let itemView = ChatChannelListItemView()
        itemView.content = .init(
            channel: .mock(cid: .unique, previewMessage: nil),
            currentUserId: nil,
            searchResult: .init(text: "Dummy", message: .mock(text: "Some text"))
        )

        XCTAssertEqual("Some text", itemView.subtitleText)
    }

    // MARK: - Timestamp

    func test_timestampText_whenPreviewMessageIsNil_thenTimestampIsNil() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: nil
        )
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)

        XCTAssertNil(itemView.timestampText)
    }

    func test_timestampText_whenPreviewMessageExists_thenUsesCreatedAtFromPreviewMessage() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: .mock(
                createdAt: Date(timeIntervalSince1970: 1)
            )
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        itemView.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()

        // Workaround for iOS 17 spacing issue
        XCTAssertTrue(
            ["12:00 AM", "12:00 AM"].contains(itemView.timestampText),
            "Actual result: \(itemView.timestampText ?? "")"
        )
    }

    func test_timestampText_whenSearchingMessage_thenUsesCreatedAtFromSearchResultMessage() {
        let itemView = ChatChannelListItemView()
        itemView.content = .init(
            channel: .mockNonDMChannel(previewMessage: nil),
            currentUserId: nil,
            searchResult: .init(
                text: "Dummy",
                message: .mock(text: "Some text", createdAt: Date(timeIntervalSince1970: 1))
            )
        )
        itemView.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()

        // Workaround for iOS 17 spacing issue
        XCTAssertTrue(
            ["12:00 AM", "12:00 AM"].contains(itemView.timestampText),
            "Actual result: \(itemView.timestampText ?? "")"
        )
    }

    func test_timestampText_whenCreatedAtIsToday_thenShowsTimeOnly() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: .mock(
                createdAt: Date(timeIntervalSince1970: 1)
            )
        )

        let mockCalendar = Calendar_Mock()
        mockCalendar.mockIsDateInToday = true
        let formatter = ChannelListMessageTimestampFormatter()
        formatter.calendar = mockCalendar

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        itemView.appearance.formatters.channelListMessageTimestamp = formatter

        // Workaround for iOS 17 spacing issue
        XCTAssertTrue(
            ["12:00 AM", "12:00 AM"].contains(itemView.timestampText),
            "Actual result: \(itemView.timestampText ?? "")"
        )
    }

    func test_timestampText_whenCreatedAtIsYesterday_thenShowsYesterday() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: .mock(
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            )
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)

        XCTAssertEqual(
            itemView.timestampText,
            "Yesterday"
        )
    }

    func test_timestampText_whenCreatedAtInLastWeek_thenShowsWeekDay() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: .mock(
                createdAt: Date(timeIntervalSince1970: 1_690_998_292)
            )
        )

        let mockCalendar = Calendar_Mock()
        mockCalendar.mockIsDateInLastWeek = true
        let formatter = ChannelListMessageTimestampFormatter()
        formatter.calendar = mockCalendar

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)
        itemView.appearance.formatters.channelListMessageTimestamp = formatter

        XCTAssertEqual(
            itemView.timestampText,
            "Wednesday"
        )
    }

    func test_timestampText_whenCreatedAtBeforeLastWeek_thenShowsDate() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            previewMessage: .mock(
                createdAt: Date(timeIntervalSince1970: 1_690_998_292)
            )
        )

        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)

        XCTAssertEqual(
            itemView.timestampText,
            "8/2/23"
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

    func test_previewMessageDeliveryStatus_whenSearchingMessage() {
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
                currentUserId: .unique,
                searchResult: .init(text: "Dummy", message: .mock())
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
        view.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()
        view.content = content
        view.addSizeConstraints()
        return view
    }

    private func channel(
        previewMessage: ChatMessage? = nil,
        readEventsEnabled: Bool,
        memberCount: Int = 0,
        membership: ChatChannelMember? = nil
    ) -> ChatChannel {
        .mock(
            cid: previewMessage?.cid ?? .unique,
            name: "Channel 1",
            imageURL: TestImages.yoda.url,
            createdAt: Date(timeIntervalSince1970: 1),
            config: .mock(readEventsEnabled: readEventsEnabled),
            membership: membership,
            memberCount: memberCount,
            previewMessage: previewMessage
        )
    }

    private func mockAudioMessage(text: String, isSentByCurrentUser: Bool) throws -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: text,
            type: .regular,
            author: .mock(id: "user", name: "User"),
            createdAt: Date(timeIntervalSince1970: 100),
            attachments: [
                .dummy(
                    type: .audio,
                    payload: try JSONEncoder().encode(AudioAttachmentPayload(
                        title: "Some Audio",
                        audioRemoteURL: URL(string: "url")!,
                        file: .init(type: .mp3, size: 123, mimeType: nil),
                        extraData: nil
                    ))
                )
            ],
            localState: nil,
            isSentByCurrentUser: isSentByCurrentUser
        )
    }

    private func mockImageMessage(text: String, isSentByCurrentUser: Bool) throws -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: text,
            type: .regular,
            author: .mock(id: "user", name: "User"),
            createdAt: Date(timeIntervalSince1970: 100),
            attachments: [
                .dummy(
                    type: .image,
                    payload: try JSONEncoder().encode(ImageAttachmentPayload(
                        title: "Test",
                        imageRemoteURL: URL(string: "Url")!
                    ))
                )
            ],
            localState: nil,
            isSentByCurrentUser: isSentByCurrentUser
        )
    }

    private func mockVideoMessage(text: String, isSentByCurrentUser: Bool) throws -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: text,
            type: .regular,
            author: .mock(id: "user", name: "User"),
            createdAt: Date(timeIntervalSince1970: 100),
            attachments: [
                .dummy(
                    type: .video,
                    payload: try JSONEncoder().encode(VideoAttachmentPayload(
                        title: "Test",
                        videoRemoteURL: URL(string: "Url")!,
                        file: .init(type: .mp4, size: 123, mimeType: nil),
                        extraData: nil
                    ))
                )
            ],
            localState: nil,
            isSentByCurrentUser: isSentByCurrentUser
        )
    }

    private func mockFileMessage(title: String?, text: String, isSentByCurrentUser: Bool) throws -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: text,
            type: .regular,
            author: .mock(id: "user", name: "User"),
            createdAt: Date(timeIntervalSince1970: 100),
            attachments: [
                .dummy(
                    type: .file,
                    payload: try JSONEncoder().encode(FileAttachmentPayload(
                        title: title,
                        assetRemoteURL: URL(string: "Url")!,
                        file: .init(type: .pdf, size: 123, mimeType: nil),
                        extraData: nil
                    ))
                )
            ],
            localState: nil,
            isSentByCurrentUser: isSentByCurrentUser
        )
    }

    private func mockGiphyMessage(text: String, isSentByCurrentUser: Bool) throws -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: text,
            type: .regular,
            author: .mock(id: "user", name: "User"),
            createdAt: Date(timeIntervalSince1970: 100),
            attachments: [
                .dummy(
                    type: .giphy,
                    payload: try JSONEncoder().encode(GiphyAttachmentPayload(
                        title: "Test",
                        previewURL: URL(string: "Url")!
                    ))
                )
            ],
            localState: nil,
            isSentByCurrentUser: isSentByCurrentUser
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

private class Calendar_Mock: ChannelListMessageTimestampCalendar {
    var mockIsDateInToday = false
    var mockIsDateInYesterday = false
    var mockIsDateInLastWeek = false

    func isDateInToday(_ date: Date) -> Bool {
        mockIsDateInToday
    }

    func isDateInYesterday(_ date: Date) -> Bool {
        mockIsDateInYesterday
    }

    func isDateInLastWeek(_ date: Date) -> Bool {
        mockIsDateInLastWeek
    }
}

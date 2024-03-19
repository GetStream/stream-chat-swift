//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatMessageContentView_Tests: XCTestCase {
    /// Default content view width.
    private let contentViewWidth: CGFloat = 360
    /// The current user.
    private let me: ChatUser = .mock(id: .unique, imageURL: TestImages.yoda.url)
    /// Another user.
    private let myFriend: ChatUser = .mock(id: .unique, imageURL: TestImages.vader.url)
    /// The `createdAt` for all test messages
    private let createdAt = DateFormatter.Stream.rfc3339Date(from: "2019-12-12T15:33:46.488935Z")!

    /// Static setUp() is only run once. Which is what we want in this case to preload the images.
    override class func setUp() {
        /// Dummy snapshot to preload the TestImages.r2.url image
        /// This was the only workaround to make sure the image always appears in the snapshots.
        let view = UIImageView(frame: .init(center: .zero, size: .init(width: 100, height: 100)))
        Components.default.imageLoader.loadImage(into: view, from: TestImages.yoda.url)
        Components.default.imageLoader.loadImage(into: view, from: TestImages.r2.url)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance() {
        let components = Components.mock

        // Iterate over messages and layouts.
        for (message, layout) in testMessagesAndLayouts {
            // Create message content view with the provided `message` and `layout`.
            let view = contentView(message: message, layout: layout, components: components)

            // Assert message content view is rendered correctly.
            AssertSnapshot(view, variants: [.defaultLight], suffix: layout.id)
        }
    }

    func test_appearanceCustomization_usingSubclassing() {
        // Create custom `ChatMessageErrorIndicator` subclass.
        class TestErrorIndicator: ChatMessageErrorIndicator {
            override func setUpAppearance() {
                super.setUpAppearance()

                // Override tint color.
                tintColor = .systemYellow
            }
        }

        // Create message for which error indicator is shown.
        let failedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Message text content",
            author: me,
            createdAt: createdAt,
            localState: .syncingFailed,
            isSentByCurrentUser: true
        )

        // Create custom components.
        var components = Components.default
        // Inject custom error indicator type.
        components.messageErrorIndicator = TestErrorIndicator.self

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: failedMessage,
            layout: failedMessage.layout(isLastInGroup: true),
            components: components
        )

        // Add view to view heirarchy to trigger lifecycle methods.
        UIView().addSubview(view)

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }

    func test_appearanceCustomization_usingUIConfig() {
        // Create message for which error indicator is shown.
        let failedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Message text content",
            author: me,
            createdAt: createdAt,
            localState: .syncingFailed,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.colorPalette.alert = .systemYellow

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: failedMessage,
            layout: failedMessage.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }

    func test_appearanceForSystemMessage() {
        // Create a system message
        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Some member was added",
            type: .system,
            author: myFriend,
            createdAt: createdAt,
            isSentByCurrentUser: false
        )

        let appearance = Appearance.default

        let view = contentView(
            message: systemMessage,
            layout: systemMessage.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }

    func test_appearanceForErrorMessage() {
        // Create a system message
        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Some member was added",
            type: .error,
            author: myFriend,
            createdAt: createdAt,
            isSentByCurrentUser: false
        )

        let appearance = Appearance.default

        let view = contentView(
            message: systemMessage,
            layout: systemMessage.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }

    func test_appearance_whenMessageFromTheCurrentUserIsPendingSend() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let pendingSendMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: "The one to be sent",
            author: me,
            createdAt: createdAt,
            localState: .sending,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: pendingSendMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageFromTheCurrentUserIsSent() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: "Sent message",
            author: me,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageWithMarkdownFromTheCurrentUserIsSent() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let messageWithMarkdown = """
          *italics* or _italics_
          **bold** or __bold__
          ~~Linethrough~~Strikethroughs.
          `let property: Double = 10.0`
        """

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: messageWithMarkdown,
            author: me,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_whenMessageWithMarkdownOrderedListFromTheCurrentUserIsSent() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let messageWithMarkdownOrderedList = """
           1. Test1
           2. Test2
           3. Test3
           4. Test4
           5. Test5
           6. Test6
           7. Test7
           8. Test8
           9. Test9
           10. Test10
           33. Test33
        """

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: messageWithMarkdownOrderedList,
            author: me,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_whenMessageWithMarkdownItalicStyleFromTheCurrentUserIsSent() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let messageWithMarkdown = """
           https://getstream.io/test_endpoint_in__snake__style
           Test_text_in__snake__style and plain text
           Test plain text and the_text_in__snake__style
           _Test text in italic style_ and plain text
           Test plain text and _text in italic style_
           Test plain text, _text in italic style_ and plain text
           Test plain text, __text in bold style__ and plain text
        """

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: messageWithMarkdown,
            author: me,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageFromTheCurrentUserIsRead_inDirectMesssagesChannel() {
        let dmChannelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 2
        )

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: dmChannelWithReadsEnabled.cid,
            text: "Read message in direct messages channel",
            author: me,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: dmChannelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageFromTheCurrentUserIsRead_inGroupChannel() {
        let groupChannelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 5
        )

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: groupChannelWithReadsEnabled.cid,
            text: "Read message in group channel",
            author: me,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: groupChannelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasLink() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "https://getstream.io/chat/docs/",
            author: me,
            createdAt: createdAt,
            attachments: [
                .dummy(
                    id: .unique,
                    type: .linkPreview,
                    payload: try JSONEncoder.stream.encode(LinkAttachmentPayload(
                        originalURL: URL(string: "https://getstream.io/chat/docs/")!,
                        title: "Chat API Documentation",
                        text: "Stream, scalable news feeds and activity streams as a service.",
                        author: "Stream",
                        previewURL: TestImages.r2.url
                    )),
                    uploadingState: nil
                )
            ],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique),
            attachmentInjector: LinkAttachmentViewInjector.self
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasLinkAndMention() throws {
        let mentionedUser = myFriend
        mentionedUser.name = "MyFriend"
        let messageWithMentionAndLink = "Hello @\(mentionedUser.name ?? "")!, check this link: getstream.io/chat/docs"

        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: messageWithMentionAndLink,
            author: me,
            createdAt: createdAt,
            mentionedUsers: [mentionedUser],
            attachments: [
                .dummy(
                    id: .unique,
                    type: .linkPreview,
                    payload: try JSONEncoder.stream.encode(LinkAttachmentPayload(
                        originalURL: URL(string: "https://getstream.io/chat/docs/")!,
                        title: "Chat API Documentation",
                        text: "Stream, scalable news feeds and activity streams as a service.",
                        author: "Stream",
                        previewURL: TestImages.r2.url
                    )),
                    uploadingState: nil
                )
            ],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique),
            attachmentInjector: LinkAttachmentViewInjector.self
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenMessageHasLinkAndMarkdown() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "## Hey!, check this link: getstream.io/chat/docs",
            author: me,
            createdAt: createdAt,
            attachments: [
                .dummy(
                    id: .unique,
                    type: .linkPreview,
                    payload: try JSONEncoder.stream.encode(LinkAttachmentPayload(
                        originalURL: URL(string: "https://getstream.io/chat/docs/")!,
                        title: "Chat API Documentation",
                        text: "Stream, scalable news feeds and activity streams as a service.",
                        author: "Stream",
                        previewURL: TestImages.r2.url
                    )),
                    uploadingState: nil
                )
            ],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique),
            attachmentInjector: LinkAttachmentViewInjector.self
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenMessageHasLinkWithoutImage() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "https://getstream.io/chat/docs/",
            author: me,
            createdAt: createdAt,
            attachments: [
                .dummy(
                    id: .unique,
                    type: .linkPreview,
                    payload: try JSONEncoder.stream.encode(LinkAttachmentPayload(
                        originalURL: URL(string: "https://getstream.io/chat/docs/")!,
                        title: "Chat API Documentation",
                        text: "Stream, scalable news feeds and activity streams as a service.",
                        author: "Stream",
                        previewURL: nil
                    )),
                    uploadingState: nil
                )
            ],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique),
            attachmentInjector: LinkAttachmentViewInjector.self
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasLinkWithoutAuthor() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "https://getstream.io/chat/docs/",
            author: me,
            createdAt: createdAt,
            attachments: [
                .dummy(
                    id: .unique,
                    type: .linkPreview,
                    payload: try JSONEncoder.stream.encode(LinkAttachmentPayload(
                        originalURL: URL(string: "https://getstream.io/chat/docs/")!,
                        title: "Chat API Documentation",
                        text: "Stream, scalable news feeds and activity streams as a service.",
                        author: nil,
                        previewURL: TestImages.r2.url
                    )),
                    uploadingState: nil
                )
            ],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique),
            attachmentInjector: LinkAttachmentViewInjector.self
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasLinkWithoutImageAndAuthor() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "https://getstream.io/chat/docs/",
            author: me,
            createdAt: createdAt,
            attachments: [
                .dummy(
                    id: .unique,
                    type: .linkPreview,
                    payload: try JSONEncoder.stream.encode(LinkAttachmentPayload(
                        originalURL: URL(string: "https://getstream.io/chat/docs/")!,
                        title: "Chat API Documentation",
                        text: "Stream, scalable news feeds and activity streams as a service.",
                        author: nil,
                        previewURL: nil
                    )),
                    uploadingState: nil
                )
            ],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique),
            attachmentInjector: LinkAttachmentViewInjector.self
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasTranslation_whenIsSentByCurrentUser() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: me,
            createdAt: createdAt,
            translations: [.portuguese: "Olá"],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .portuguese))
        )
        view.layoutOptions?.insert(.translation)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasTranslation_whenNotSentByCurrentUser() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: .unique,
            createdAt: createdAt,
            translations: [.portuguese: "Olá"],
            localState: nil,
            isSentByCurrentUser: false
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .portuguese))
        )
        view.layoutOptions?.insert(.translation)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageHasTranslation_whenHasAttachment() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: .unique,
            createdAt: createdAt,
            translations: [.portuguese: "Olá"],
            attachments: [.dummy(
                id: .unique,
                type: .image,
                payload: try JSONEncoder.stream.encode(ImageAttachmentPayload(
                    title: nil,
                    imageRemoteURL: TestImages.r2.url
                )),
                uploadingState: nil
            )],
            localState: nil,
            isSentByCurrentUser: false
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .portuguese)),
            attachmentInjector: GalleryAttachmentViewInjector.self
        )
        view.layoutOptions?.insert(.translation)

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenMessageHasTranslation_whenNotLastInGroup() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: .unique,
            createdAt: createdAt,
            translations: [.portuguese: "Olá"],
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .portuguese)),
            layout: message.layout(isLastInGroup: false)
        )
        view.layoutOptions?.insert(.translation)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenQuoteMessageHasTranslation() throws {
        let quotedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            author: .unique,
            createdAt: createdAt,
            translations: [.portuguese: "Olá"],
            localState: nil,
            isSentByCurrentUser: true
        )

        let message: ChatMessage = .mock(id: .unique, text: "Reply Text", quotedMessage: quotedMessage)

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .portuguese))
        )
        view.layoutOptions?.insert(.translation)

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenMessageIsBounced() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello",
            type: .error,
            author: .unique,
            createdAt: createdAt,
            isBounced: true,
            localState: nil,
            isSentByCurrentUser: true
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique)
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenMessageIsEdited() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello World",
            author: .unique,
            createdAt: createdAt,
            localState: nil,
            isSentByCurrentUser: true,
            textUpdatedAt: .unique
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique)
        )
        view.components.isMessageEditedLabelEnabled = true

        AssertSnapshot(view, variants: .all)
    }

    func test_appearance_whenMessageIsEdited_andDeleted_shouldNotShowEditedLabel() throws {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello World",
            author: .unique,
            createdAt: createdAt,
            deletedAt: .unique,
            localState: nil,
            isSentByCurrentUser: true,
            textUpdatedAt: .unique
        )

        let view = contentView(
            message: message,
            channel: .mock(cid: .unique)
        )
        view.components.isMessageEditedLabelEnabled = true

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_chatReactionsBubbleViewInjectable() {
        let testMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Some long text goes here.",
            author: me,
            createdAt: createdAt,
            reactionScores: [
                "like": 5,
                "love": 2
            ],
            isSentByCurrentUser: true
        )

        // Given
        // Create custom `ChatReactionsBubbleView` subclass.
        class CustomChatReactionsBubbleView: ChatReactionsBubbleView {
            override func setUpAppearance() {
                super.setUpAppearance()
                backgroundColor = .black
            }
        }

        // When
        var components = Components.default
        components.messageReactionsBubbleView = CustomChatReactionsBubbleView.self
        let view = contentView(
            message: testMessage,
            layout: testMessage.layout(isLastInGroup: true),
            components: components
        )

        // Add view to view heirarchy to trigger lifecycle methods.
        UIView().addSubview(view)

        // Then
        let reactionBubbleView = view.reactionsBubbleView
        XCTAssertNotNil(reactionBubbleView)
        XCTAssert(reactionBubbleView is CustomChatReactionsBubbleView)
    }

    func test_appearance_whenMessageWithAMentionedUserIsSent() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let mentionedUser = myFriend
        mentionedUser.name = "MyFriend"
        let messageWithMention = "Hello @\(mentionedUser.name ?? "")!, how are you?"

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: messageWithMention,
            author: me,
            createdAt: createdAt,
            mentionedUsers: [mentionedUser],
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageWithAMentionedUserIsSent_whenNoName() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let mentionedUser = ChatUser.mock(id: "user-id")
        mentionedUser.name = nil
        let messageWithMention = "Hello @\(mentionedUser.id)!, how are you?"

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: messageWithMention,
            author: me,
            createdAt: createdAt,
            mentionedUsers: [mentionedUser],
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageWithAMentionedUserIsSent_whenDuplicatedMentions() {
        let channelWithReadsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let mentionedUser = ChatUser.mock(id: .unique, name: "Leia")
        let messageWithMention = "Hello @\(mentionedUser.name ?? "")!, how are you @\(mentionedUser.name ?? "")?"

        let sentMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: channelWithReadsEnabled.cid,
            text: messageWithMention,
            author: me,
            createdAt: createdAt,
            mentionedUsers: [mentionedUser, mentionedUser],
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let view = contentView(
            message: sentMessageFromCurrentUser,
            channel: channelWithReadsEnabled
        )

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_textViewShouldInteractWithUrl_whenMentionedUserTapped_callsDelegate_returnsFalse() {
        let mentionedUser = myFriend
        mentionedUser.name = "MyFriend"

        let messageWithMentions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: me,
            createdAt: createdAt,
            mentionedUsers: [mentionedUser],
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let textViewUserMentionsHandler = TextViewUserMentionsHandler_Mock()
        textViewUserMentionsHandler.mockMentionedUser = mentionedUser

        let chatMessageViewContentDelegate = ChatMessageContentViewDelegate_Mock()

        let view = contentView(
            message: messageWithMentions
        )
        view.textViewUserMentionsHandler = textViewUserMentionsHandler
        view.delegate = chatMessageViewContentDelegate

        let shouldInteract = view.textView(
            UITextView(),
            shouldInteractWith: URL(string: "url")!,
            in: .init(location: 4, length: 7),
            interaction: .invokeDefaultAction
        )

        XCTAssertEqual(shouldInteract, false)
        XCTAssertEqual(chatMessageViewContentDelegate.tappedMentionedUser, mentionedUser)
        XCTAssertEqual(chatMessageViewContentDelegate.messageContentViewDidTapOnMentionedUserCallCount, 1)
    }

    func test_textViewShouldInteractWithUrl_whenMentionedUserNotTapped_doesNotCallDelegate_returnsTrue() {
        let mentionedUser = myFriend
        mentionedUser.name = "MyFriend"

        let messageWithMentions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: me,
            createdAt: createdAt,
            mentionedUsers: [mentionedUser],
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        let textViewUserMentionsHandler = TextViewUserMentionsHandler_Mock()
        textViewUserMentionsHandler.mockMentionedUser = nil

        let chatMessageViewContentDelegate = ChatMessageContentViewDelegate_Mock()

        let view = contentView(
            message: messageWithMentions
        )
        view.textViewUserMentionsHandler = textViewUserMentionsHandler
        view.delegate = chatMessageViewContentDelegate

        let shouldInteract = view.textView(
            UITextView(),
            shouldInteractWith: URL(string: "url")!,
            in: .init(location: 4, length: 7),
            interaction: .invokeDefaultAction
        )

        XCTAssertEqual(shouldInteract, true)
        XCTAssertEqual(chatMessageViewContentDelegate.messageContentViewDidTapOnMentionedUserCallCount, 0)
    }

    func test_handleTapOnQuotedMessage() {
        let quotedMessage = ChatMessage.mock()
        let messageWithQuotedMessage: ChatMessage = .mock(quotedMessage: quotedMessage)

        let chatMessageViewContentDelegate = ChatMessageContentViewDelegate_Mock()
        let view = contentView(
            message: messageWithQuotedMessage
        )
        view.delegate = chatMessageViewContentDelegate

        view.handleTapOnQuotedMessage()

        XCTAssertEqual(chatMessageViewContentDelegate.tappedQuotedMessage, quotedMessage)
        XCTAssertEqual(chatMessageViewContentDelegate.messageContentViewDidTapOnQuotedMessageCallCount, 1)
    }
}

// MARK: - Helpers

private extension ChatMessageContentView_Tests {
    var testMessagesAndLayouts: [(ChatMessage, ChatMessageLayoutOptions)] {
        testMessages
            .map { [
                ($0, $0.layout(isLastInGroup: true)),
                ($0, $0.layout(isLastInGroup: false))
            ] }
            .flatMap { $0 }
    }

    var testMessages: [ChatMessage] {
        let quotedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Thought to be quoted.",
            author: myFriend,
            isSentByCurrentUser: true
        )

        let reply: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "Some text reply.",
            author: myFriend,
            isSentByCurrentUser: false
        )

        let outgoing: [ChatMessage] = [
            // [.text] content
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                isSentByCurrentUser: true
            ),
            // [.text, .reactions]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ],
                isSentByCurrentUser: true
            ),
            // [.text, .quotedMessage]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                isSentByCurrentUser: true
            ),
            // [.text, .reactions, .quotedMessage]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ],
                isSentByCurrentUser: true
            ),
            // [.text, .reactions, .quotedMessage, .replies]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                replyCount: 20,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ],
                threadParticipants: [myFriend],
                latestReplies: [
                    reply
                ],
                isSentByCurrentUser: true
            ),
            // [.text, .reactions, .quotedMessage, .replies, .error]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                replyCount: 20,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ],
                threadParticipants: [myFriend],
                latestReplies: [
                    reply
                ],
                localState: .syncingFailed,
                isSentByCurrentUser: true
            )
        ]

        let incoming: [ChatMessage] = [
            // [.text]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt
            ),
            // [.text, .reactions]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ]
            ),
            // [.text, .quotedMessage]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt,
                quotedMessage: quotedMessage
            ),
            // [.text, .reactions, .quotedMessage]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ]
            ),
            // [.text, .reactions, .quotedMessage, .replies]
            .mock(
                id: .unique,
                cid: .unique,
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                replyCount: 20,
                reactionScores: [
                    "like": 5,
                    "love": 2
                ],
                threadParticipants: [myFriend],
                latestReplies: [
                    reply
                ]
            )
        ]

        return outgoing + incoming
    }

    func contentView(
        message: ChatMessage,
        channel: ChatChannel = .mock(cid: .unique),
        layout: ChatMessageLayoutOptions? = nil,
        appearance: Appearance = .default,
        components: Components = .default,
        attachmentInjector: AttachmentViewInjector.Type? = nil
    ) -> ChatMessageContentView {
        let layoutOptions = layout ?? components.messageLayoutOptionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        let view = ChatMessageContentView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: contentViewWidth).isActive = true
        view.appearance = appearance
        view.components = components
        view.setUpLayoutIfNeeded(options: layoutOptions, attachmentViewInjectorType: attachmentInjector)
        view.content = message
        view.channel = channel
        return view
    }
}

extension ChatMessage {
    func layout(isLastInGroup: Bool) -> ChatMessageLayoutOptions {
        guard type != .system && type != .error else {
            return [.centered, .text]
        }

        var options: ChatMessageLayoutOptions = [
            .bubble
        ]

        if isSentByCurrentUser {
            options.insert(.flipped)
        }
        if !isLastInGroup {
            options.insert(.continuousBubble)
        }
        if !isLastInGroup && !isSentByCurrentUser {
            options.insert(.avatarSizePadding)
        }
        if isLastInGroup {
            options.insert(.timestamp)
        }
        if isLastInGroup, isSentByCurrentUser, type == .deleted || type == .ephemeral {
            options.insert(.onlyVisibleToYouIndicator)
        }
        if textContent?.isEmpty == false {
            options.insert(.text)
        }

        guard isDeleted == false else {
            return options
        }

        if isLastInGroup && !isSentByCurrentUser {
            options.insert(.avatar)
        }
        if quotedMessage != nil {
            options.insert(.quotedMessage)
        }
        if isRootOfThread {
            options.insert(.threadInfo)
            options.insert(.continuousBubble)
        }
        if !reactionScores.isEmpty {
            options.insert(.reactions)
        }
        if isLastActionFailed {
            options.insert(.errorIndicator)
        }

        return options
    }
}

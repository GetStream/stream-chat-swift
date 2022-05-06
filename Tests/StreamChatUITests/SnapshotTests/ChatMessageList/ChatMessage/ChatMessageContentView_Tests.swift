//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
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

    func test_ChatReactionsBubbleViewInjectable() {
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
        components: Components = .default
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
        view.setUpLayoutIfNeeded(options: layoutOptions, attachmentViewInjectorType: nil)
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

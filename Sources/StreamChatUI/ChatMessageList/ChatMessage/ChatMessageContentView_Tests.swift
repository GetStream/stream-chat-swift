//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
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
    private let createdAt = DateFormatter.Stream.iso8601Date(from: "2019-12-12T15:33:46.488935Z")!

    func test_appearance() {
        // Iterate over messages and layouts.
        for (message, layout) in testMessagesAndLayouts {
            // Create message content view with the provided `message` and `layout`.
            let view = contentView(message: message, layout: layout)

            // Assert message content view is rendered correctly.
            AssertSnapshot(view, variants: [.defaultLight], suffix: layout.description)
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
    
    func test_markdownBold() {
        // Create message for which error indicator is shown.
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "not bold **bold**",
            author: me,
            createdAt: createdAt,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.isMarkdownEnabled = true

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: message,
            layout: message.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }
    
    func test_markdownItalic() {
        // Create message for which error indicator is shown.
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "not italic *italic*",
            author: me,
            createdAt: createdAt,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.isMarkdownEnabled = true

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: message,
            layout: message.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }
    
    func test_markdownMono() {
        // Create message for which error indicator is shown.
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "`let message = ChatMessage.mock()`",
            author: me,
            createdAt: createdAt,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.isMarkdownEnabled = true

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: message,
            layout: message.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }
    
    func test_markdownHeader() {
        // Create message for which error indicator is shown.
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "# Header 1",
            author: me,
            createdAt: createdAt,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.isMarkdownEnabled = true

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: message,
            layout: message.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }
    
    func test_markdownUnorderedList() {
        // Create message for which error indicator is shown.
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "* one\n* two\n* three",
            author: me,
            createdAt: createdAt,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.isMarkdownEnabled = true

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: message,
            layout: message.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }
    
    func test_markdownOrderedList() {
        // Create message for which error indicator is shown.
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "1. one\n1. two\n1. three",
            author: me,
            createdAt: createdAt,
            isSentByCurrentUser: true
        )

        // Create custom Appearance.
        var appearance = Appearance.default
        // Inject custom `alert` colour.
        appearance.isMarkdownEnabled = true

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: message,
            layout: message.layout(isLastInGroup: true),
            appearance: appearance
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
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
                latestReplies: [
                    reply
                ]
            )
        ]

        return outgoing + incoming
    }

    func contentView(
        message: ChatMessage,
        layout: ChatMessageLayoutOptions,
        appearance: Appearance = .default,
        components: Components = .default
    ) -> ChatMessageContentView {
        let view = ChatMessageContentView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: contentViewWidth).isActive = true
        view.appearance = appearance
        view.components = components
        view.setUpLayoutIfNeeded(options: layout, attachmentViewInjectorType: nil)
        view.content = message
        return view
    }
}

extension _ChatMessage {
    func layout(isLastInGroup: Bool) -> ChatMessageLayoutOptions {
        guard type != .system else {
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
        if isLastInGroup && isOnlyVisibleForCurrentUser {
            options.insert(.onlyVisibleForYouIndicator)
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

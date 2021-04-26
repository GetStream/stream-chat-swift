//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class MessageContentView_Tests: XCTestCase {
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
            text: "Message text content",
            author: me,
            createdAt: createdAt,
            localState: .syncingFailed,
            isSentByCurrentUser: true
        )

        // Create custom UI config.
        var config = UIConfig.default
        // Inject custom error indicator type.
        config.messageList.messageContentSubviews.errorIndicator = TestErrorIndicator.self

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: failedMessage,
            layout: layout(for: failedMessage, isLastInGroup: true),
            uiConfig: config
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }

    func test_appearanceCustomization_usingUIConfig() {
        // Create message for which error indicator is shown.
        let failedMessage: ChatMessage = .mock(
            id: .unique,
            text: "Message text content",
            author: me,
            createdAt: createdAt,
            localState: .syncingFailed,
            isSentByCurrentUser: true
        )

        // Create custom UI config.
        var config = UIConfig.default
        // Inject custom `alert` colour.
        config.colorPalette.alert = .systemYellow

        // Create message content view with the provided `message`, `layout`, and `config`
        let view = contentView(
            message: failedMessage,
            layout: layout(for: failedMessage, isLastInGroup: true),
            uiConfig: config
        )

        // Assert message content view is rendered correctly.
        AssertSnapshot(view)
    }
}

// MARK: - Helpers

private extension MessageContentView_Tests {
    var testMessagesAndLayouts: [(ChatMessage, MessageLayoutOptions)] {
        testMessages
            .map { [
                ($0, layout(for: $0, isLastInGroup: true)),
                ($0, layout(for: $0, isLastInGroup: false))
            ] }
            .flatMap { $0 }
    }

    var testMessages: [ChatMessage] {
        let quotedMessage: ChatMessage = .mock(
            id: .unique,
            text: "Thought to be quoted.",
            author: myFriend,
            isSentByCurrentUser: true
        )

        let reply: ChatMessage = .mock(
            id: .unique,
            text: "Some text reply.",
            author: myFriend,
            isSentByCurrentUser: false
        )

        let outgoing: [ChatMessage] = [
            // [.text] content
            .mock(
                id: .unique,
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                isSentByCurrentUser: true
            ),
            // [.text, .reactions]
            .mock(
                id: .unique,
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
                text: "Some long text goes here.",
                author: me,
                createdAt: createdAt,
                quotedMessage: quotedMessage,
                isSentByCurrentUser: true
            ),
            // [.text, .reactions, .quotedMessage]
            .mock(
                id: .unique,
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
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt
            ),
            // [.text, .reactions]
            .mock(
                id: .unique,
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
                text: "Some long text goes here.",
                author: myFriend,
                createdAt: createdAt,
                quotedMessage: quotedMessage
            ),
            // [.text, .reactions, .quotedMessage]
            .mock(
                id: .unique,
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

    func layout(for message: ChatMessage, isLastInGroup: Bool) -> MessageLayoutOptions {
        var options: MessageLayoutOptions = [
            .bubble
        ]

        if message.isSentByCurrentUser {
            options.insert(.flipped)
        }
        if !isLastInGroup {
            options.insert(.continuousBubble)
        }
        if !isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatarSizePadding)
        }
        if isLastInGroup {
            options.insert(.metadata)
        }
        if message.textContent?.isEmpty == false {
            options.insert(.text)
        }

        guard message.deletedAt == nil else {
            return options
        }

        if isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatar)
        }
        if message.quotedMessage != nil {
            options.insert(.quotedMessage)
        }
        if message.isPartOfThread {
            options.insert(.threadInfo)
            options.insert(.continuousBubble)
        }
        if !message.reactionScores.isEmpty {
            options.insert(.reactions)
        }
        if message.lastActionFailed {
            options.insert(.error)
        }

        return options
    }

    func contentView(
        message: ChatMessage,
        layout: MessageLayoutOptions,
        uiConfig: UIConfig = .default
    ) -> MessageContentView {
        let view = MessageContentView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: contentViewWidth).isActive = true
        view.uiConfig = uiConfig
        view.setUpLayoutIfNeeded(options: layout)
        view.content = message
        return view
    }
}

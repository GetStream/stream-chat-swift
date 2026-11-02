//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension AIConversationView {
    /// Shows an ``AIChat`` with the views of `viewFactory`, and follows it as it changes.
    ///
    /// The person's latest message offers to edit it, and each finished reply to rate it, the
    /// latest also to regenerate it. The factory's default views show these, and views of your
    /// own find them in their options.
    ///
    /// - Parameters:
    ///   - chat: The conversation, and what the person does in it.
    ///   - viewFactory: The views of the messages, and the actions under each finished reply.
    ///   - footer: A view under the latest turn's messages, such as the chat's error with a way
    ///     to retry. It is made again each time the chat changes.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Factory: AIConversationViewFactory>(
        chat: AIChat<Item>,
        viewFactory: Factory,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>, MessageContent == EquatableView<AIConversationEntryView<Item, Factory>> {
        let loadOlderMessages: @MainActor () async -> Void = { await chat.loadOlderMessages() }
        self.init(
            content: { tracker in
                let messages = chat.messages
                let pending = chat.pendingMessage
                let entries = tracker.entries(for: messages, pending: pending)
                let isThinking = chat.status == .submitted || tracker.isAwaitingReply(in: messages, pending: pending)
                return (entries, isThinking)
            },
            isSentByCurrentUser: \.isFromUser,
            loadOlderMessages: { chat.hasOlderMessages ? loadOlderMessages : nil },
            messageContent: { (entry: AIConversationEntry<Item>) in
                AIConversationEntryView(entry: entry, factory: viewFactory, approver: chat.approver, chat: chat).equatable()
            },
            footer: footer,
            emptyContent: emptyContent,
            changes: chat.changes
        )
    }

    /// Shows an ``AIChat`` with ``AIUserMessageView``, ``AIAssistantMessageView`` and, under each
    /// finished reply, ``AIReplyActionsView``, and follows it as it changes.
    ///
    /// - Parameters:
    ///   - chat: The conversation, and what the person does in it.
    ///   - footer: A view under the latest turn's messages, such as the chat's error with a way
    ///     to retry. It is made again each time the chat changes.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage>(
        chat: AIChat<Item>,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIConversationEntryView<Item, DefaultAIConversationViewFactory>> {
        self.init(
            chat: chat,
            viewFactory: DefaultAIConversationViewFactory.shared,
            footer: footer,
            emptyContent: emptyContent
        )
    }
}

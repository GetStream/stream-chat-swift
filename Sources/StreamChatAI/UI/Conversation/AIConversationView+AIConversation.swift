//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
public extension AIConversationView {
    /// Shows an ``AIConversation`` with the views of `viewFactory`, and follows it as it changes.
    ///
    /// The person's latest message offers to edit it, and each finished reply to rate it, the
    /// latest also to regenerate it, as the conversation's ``AIConversation/actions`` allow. The
    /// factory's default views show these, and views of your own find them in their options.
    ///
    /// - Parameters:
    ///   - conversation: The conversation, and what the person does in it.
    ///   - viewFactory: The views of the messages, and the actions under each finished reply.
    ///   - footer: A view under the latest turn's messages, or under the empty content while
    ///     there are none, such as the conversation's error with a way to retry. It is made again
    ///     each time the conversation changes.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Factory: AIConversationViewFactory>(
        conversation: AIConversation<Item>,
        viewFactory: Factory,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>, MessageContent == EquatableView<AIConversationEntryView<Item, Factory>> {
        let loadOlderMessages: @MainActor () async -> Void = { await conversation.loadOlderMessages() }
        self.init(
            content: { tracker in
                // The conversation knows when its agent is thinking, including after a stop or a
                // failure that leaves the person's message on its way.
                let entries = tracker.entries(for: conversation.messages, pending: conversation.pendingMessage)
                return (entries, conversation.status == .submitted)
            },
            isSentByCurrentUser: \.isFromUser,
            loadOlderMessages: { conversation.hasOlderMessages ? loadOlderMessages : nil },
            messageContent: { (entry: AIConversationEntry<Item>) in
                AIConversationEntryView(
                    entry: entry,
                    factory: viewFactory,
                    approver: conversation.approver,
                    conversation: conversation
                )
                .equatable()
            },
            footer: footer,
            emptyContent: emptyContent,
            changes: conversation.changes
        )
    }

    /// Shows an ``AIConversation`` with ``AIUserMessageView``, ``AIAssistantMessageView`` and, under each
    /// finished reply, ``AIReplyActionsView``, and follows it as it changes.
    ///
    /// - Parameters:
    ///   - conversation: The conversation, and what the person does in it.
    ///   - footer: A view under the latest turn's messages, or under the empty content while
    ///     there are none, such as the conversation's error with a way to retry. It is made again
    ///     each time the conversation changes.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage>(
        conversation: AIConversation<Item>,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIConversationEntryView<Item, DefaultAIConversationViewFactory>> {
        self.init(
            conversation: conversation,
            viewFactory: DefaultAIConversationViewFactory.shared,
            footer: footer,
            emptyContent: emptyContent
        )
    }
}

@available(iOS 15.0, macOS 12.0, *)
public extension AIConversationView {
    /// Shows an ``AIConversation`` with the views of `viewFactory`, and a reply's generated UI in
    /// place of its text, from the renderers of `ui`, and follows it as it changes.
    ///
    /// The person's latest message offers to edit it, and each finished reply to rate it, the
    /// latest also to regenerate it, as the conversation's ``AIConversation/actions`` allow. The
    /// factory's default views show these, and views of your own find them in their options.
    ///
    /// - Parameters:
    ///   - conversation: The conversation, and what the person does in it.
    ///   - ui: The conversation's generated UI: the renderers of the formats the agent writes, and
    ///     the app's components. A reply whose UI none of them reads shows its text.
    ///   - viewFactory: The views of the messages, and the actions under each finished reply.
    ///   - footer: A view under the latest turn's messages, or under the empty content while
    ///     there are none, such as the conversation's error with a way to retry. It is made again
    ///     each time the conversation changes.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Factory: AIConversationViewFactory, Renderers: AIUIRendererList>(
        conversation: AIConversation<Item>,
        ui: AIUIHost<Renderers>?,
        viewFactory: Factory,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIUIConversationEntryView<Item, Factory, Renderers>> {
        let loadOlderMessages: @MainActor () async -> Void = { await conversation.loadOlderMessages() }
        self.init(
            content: { tracker in
                let messages = conversation.messages
                // The rows show only the replies on screen, so the engines take every reply's UI first.
                ui?.receive(messages)
                let entries = tracker.entries(for: messages, pending: conversation.pendingMessage, ui: ui)
                // A reply that shows only its UI has started, which the conversation can't tell
                // without the host that reads it.
                let showsReply = entries.last.map { !$0.isFromUser } ?? false
                return (entries, conversation.status == .submitted && !showsReply)
            },
            isSentByCurrentUser: \.isFromUser,
            loadOlderMessages: { conversation.hasOlderMessages ? loadOlderMessages : nil },
            messageContent: { (entry: AIConversationEntry<Item>) in
                AIUIConversationEntryView(
                    entry: entry,
                    factory: viewFactory,
                    approver: conversation.approver,
                    host: ui,
                    conversation: conversation
                )
                .equatable()
            },
            footer: footer,
            emptyContent: emptyContent,
            changes: conversation.changes
        )
    }

    /// Shows an ``AIConversation`` with ``AIUserMessageView``, ``AIAssistantMessageView`` and, under
    /// each finished reply, ``AIReplyActionsView``, and a reply's generated UI in place of its text,
    /// from the renderers of `ui`, and follows it as it changes.
    ///
    /// - Parameters:
    ///   - conversation: The conversation, and what the person does in it.
    ///   - ui: The conversation's generated UI: the renderers of the formats the agent writes, and
    ///     the app's components. A reply whose UI none of them reads shows its text.
    ///   - footer: A view under the latest turn's messages, or under the empty content while
    ///     there are none, such as the conversation's error with a way to retry. It is made again
    ///     each time the conversation changes.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Renderers: AIUIRendererList>(
        conversation: AIConversation<Item>,
        ui: AIUIHost<Renderers>?,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIUIConversationEntryView<Item, DefaultAIConversationViewFactory, Renderers>> {
        self.init(
            conversation: conversation,
            ui: ui,
            viewFactory: DefaultAIConversationViewFactory.shared,
            footer: footer,
            emptyContent: emptyContent
        )
    }
}

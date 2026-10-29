//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension AIConversationView {
    /// Shows ``AIMessage``s with the views of `viewFactory`. A reply joins the list once it shows
    /// something; until then the list shows the agent thinking.
    ///
    /// - Parameters:
    ///   - messages: The conversation, oldest message first.
    ///   - pendingMessage: A message the person sent that is not in `messages` yet. Keep passing
    ///     it until its reply starts: the list stops showing it once its copy arrives.
    ///   - isThinking: Whether the agent is answering the latest message and its reply shows
    ///     nothing yet. The list also knows it is while `pendingMessage` waits, and while the
    ///     latest reply is being written but shows nothing.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device, to ask them.
    ///   - loadOlderMessages: Loads the messages before the first one, which the list asks for
    ///     as the person scrolls to its start. It shows a spinner meanwhile, and what is on
    ///     screen stays in place as they arrive. Pass nil once there are none left.
    ///   - viewFactory: The views of the messages, and the actions under each finished reply.
    ///   - footer: A view under the latest turn's messages, such as what the agent is doing, or
    ///     an error with a way to retry.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Factory: AIConversationViewFactory>(
        messages: [Item],
        pendingMessage: AIPendingMessage? = nil,
        isThinking: Bool = false,
        approver: AIToolApprover? = nil,
        loadOlderMessages: (@MainActor () async -> Void)? = nil,
        viewFactory: Factory,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>, MessageContent == EquatableView<AIConversationEntryView<Item, Factory>> {
        self.init(
            content: { tracker in
                let entries = tracker.entries(for: messages, pending: pendingMessage)
                return (entries, isThinking || tracker.isAwaitingReply(in: messages, pending: pendingMessage))
            },
            isSentByCurrentUser: \.isFromUser,
            loadOlderMessages: loadOlderMessages,
            messageContent: { entry in
                AIConversationEntryView(entry: entry, factory: viewFactory, approver: approver).equatable()
            },
            footer: footer(),
            emptyContent: emptyContent()
        )
    }

    /// Shows ``AIMessage``s with ``AIUserMessageView`` and ``AIAssistantMessageView``. A reply
    /// joins the list once it shows something; until then the list shows the agent thinking.
    ///
    /// - Parameters:
    ///   - messages: The conversation, oldest message first.
    ///   - pendingMessage: A message the person sent that is not in `messages` yet. Keep passing
    ///     it until its reply starts: the list stops showing it once its copy arrives.
    ///   - isThinking: Whether the agent is answering the latest message and its reply shows
    ///     nothing yet. The list also knows it is while `pendingMessage` waits, and while the
    ///     latest reply is being written but shows nothing.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device, to ask them.
    ///   - loadOlderMessages: Loads the messages before the first one, which the list asks for
    ///     as the person scrolls to its start. It shows a spinner meanwhile, and what is on
    ///     screen stays in place as they arrive. Pass nil once there are none left.
    ///   - footer: A view under the latest turn's messages, such as what the agent is doing, or
    ///     an error with a way to retry.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage>(
        messages: [Item],
        pendingMessage: AIPendingMessage? = nil,
        isThinking: Bool = false,
        approver: AIToolApprover? = nil,
        loadOlderMessages: (@MainActor () async -> Void)? = nil,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIConversationEntryView<Item, DefaultAIConversationViewFactory>> {
        self.init(
            messages: messages,
            pendingMessage: pendingMessage,
            isThinking: isThinking,
            approver: approver,
            loadOlderMessages: loadOlderMessages,
            viewFactory: DefaultAIConversationViewFactory.shared,
            footer: footer,
            emptyContent: emptyContent
        )
    }
}

public extension AIConversationView {
    /// Shows ``AIMessage``s with the views of `viewFactory`, and a reply's generated UI in place
    /// of its text, from the renderers of `ui`. A reply joins the list once it shows something;
    /// until then the list shows the agent thinking.
    ///
    /// - Parameters:
    ///   - messages: The conversation, oldest message first.
    ///   - pendingMessage: A message the person sent that is not in `messages` yet. Keep passing
    ///     it until its reply starts: the list stops showing it once its copy arrives.
    ///   - isThinking: Whether the agent is answering the latest message and its reply shows
    ///     nothing yet. The list also knows it is while `pendingMessage` waits, and while the
    ///     latest reply is being written but shows nothing.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device, to ask them.
    ///   - ui: The conversation's generated UI: the renderers of the formats the agent writes, and
    ///     the app's components. A reply whose UI none of them reads shows its text.
    ///   - loadOlderMessages: Loads the messages before the first one, which the list asks for
    ///     as the person scrolls to its start. It shows a spinner meanwhile, and what is on
    ///     screen stays in place as they arrive. Pass nil once there are none left.
    ///   - viewFactory: The views of the messages, and the actions under each finished reply.
    ///   - footer: A view under the latest turn's messages, such as what the agent is doing, or
    ///     an error with a way to retry.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Factory: AIConversationViewFactory, Renderers: AIUIRenderers>(
        messages: [Item],
        pendingMessage: AIPendingMessage? = nil,
        isThinking: Bool = false,
        approver: AIToolApprover? = nil,
        ui: AIUIHost<Renderers>?,
        loadOlderMessages: (@MainActor () async -> Void)? = nil,
        viewFactory: Factory,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIUIConversationEntryView<Item, Factory, Renderers>> {
        self.init(
            content: { tracker in
                let entries = tracker.entries(for: messages, pending: pendingMessage)
                return (entries, isThinking || tracker.isAwaitingReply(in: messages, pending: pendingMessage))
            },
            isSentByCurrentUser: \.isFromUser,
            loadOlderMessages: loadOlderMessages,
            messageContent: { entry in
                AIUIConversationEntryView(entry: entry, factory: viewFactory, approver: approver, host: ui).equatable()
            },
            footer: footer(),
            emptyContent: emptyContent()
        )
    }

    /// Shows ``AIMessage``s with ``AIUserMessageView`` and ``AIAssistantMessageView``, and a
    /// reply's generated UI in place of its text, from the renderers of `ui`. A reply joins the
    /// list once it shows something; until then the list shows the agent thinking.
    ///
    /// - Parameters:
    ///   - messages: The conversation, oldest message first.
    ///   - pendingMessage: A message the person sent that is not in `messages` yet. Keep passing
    ///     it until its reply starts: the list stops showing it once its copy arrives.
    ///   - isThinking: Whether the agent is answering the latest message and its reply shows
    ///     nothing yet. The list also knows it is while `pendingMessage` waits, and while the
    ///     latest reply is being written but shows nothing.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device, to ask them.
    ///   - ui: The conversation's generated UI: the renderers of the formats the agent writes, and
    ///     the app's components. A reply whose UI none of them reads shows its text.
    ///   - loadOlderMessages: Loads the messages before the first one, which the list asks for
    ///     as the person scrolls to its start. It shows a spinner meanwhile, and what is on
    ///     screen stays in place as they arrive. Pass nil once there are none left.
    ///   - footer: A view under the latest turn's messages, such as what the agent is doing, or
    ///     an error with a way to retry.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    init<Item: AIMessage, Renderers: AIUIRenderers>(
        messages: [Item],
        pendingMessage: AIPendingMessage? = nil,
        isThinking: Bool = false,
        approver: AIToolApprover? = nil,
        ui: AIUIHost<Renderers>?,
        loadOlderMessages: (@MainActor () async -> Void)? = nil,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: () -> EmptyContent = { EmptyView() }
    ) where Message == AIConversationEntry<Item>,
        MessageContent == EquatableView<AIUIConversationEntryView<Item, DefaultAIConversationViewFactory, Renderers>> {
        self.init(
            messages: messages,
            pendingMessage: pendingMessage,
            isThinking: isThinking,
            approver: approver,
            ui: ui,
            loadOlderMessages: loadOlderMessages,
            viewFactory: DefaultAIConversationViewFactory.shared,
            footer: footer,
            emptyContent: emptyContent
        )
    }
}

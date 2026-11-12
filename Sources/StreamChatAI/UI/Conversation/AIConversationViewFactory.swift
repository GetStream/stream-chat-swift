//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The views ``AIConversationView`` shows ``AIMessage``s with.
///
/// Each has a default, so override only the ones you want to change. Under a finished reply
/// there is nothing by default: offer the person what your app does with replies there, such as
/// copying, rating or regenerating them. A list that shows an ``AIConversation`` offers them with
/// ``AIReplyActionsView`` by default.
///
/// ```swift
/// final class MyFactory: AIConversationViewFactory {
///     let chat: Chat
///
///     init(chat: Chat) {
///         self.chat = chat
///     }
///
///     func makeReplyActionsView(options: AIReplyActionsViewOptions) -> some View {
///         AIReplyActionsView(
///             text: options.text,
///             actions: AIReplyActions(onRegenerate: options.isLatestReply ? { chat.regenerate() } : nil)
///         )
///     }
/// }
///
/// AIConversationView(messages: messages, viewFactory: MyFactory(chat: chat))
/// ```
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public protocol AIConversationViewFactory {
    /// The view type returned by ``makeUserMessageView(options:)``.
    associatedtype UserMessageViewType: View
    /// Returns the view of a message the person sent, ``AIUserMessageView`` by default.
    func makeUserMessageView(options: AIUserMessageViewOptions) -> UserMessageViewType

    /// The view type returned by ``makeAssistantMessageView(options:)``.
    associatedtype AssistantMessageViewType: View
    /// Returns the view of a reply, ``AIAssistantMessageView`` by default.
    func makeAssistantMessageView(options: AIAssistantMessageViewOptions) -> AssistantMessageViewType

    /// The view type returned by ``makeReplyActionsView(options:)``.
    associatedtype ReplyActionsViewType: View
    /// Returns what the person can do with a finished reply, shown under it once its answer is
    /// written out. Empty by default, or, in a list that shows an ``AIConversation``,
    /// ``AIReplyActionsView`` with the conversation's actions from the options.
    ///
    /// A reply's row is not made again while it shows the same, so read what changes, such as
    /// the person's rating, from an observable model rather than capturing it.
    func makeReplyActionsView(options: AIReplyActionsViewOptions) -> ReplyActionsViewType

    /// The view type returned by ``makeAttachmentView(options:)``.
    associatedtype AttachmentViewType: View
    /// Returns the view of one of a message's attachments, ``AIMessageAttachmentView`` by
    /// default, which shows images as thumbnails and every other kind as a file. Return your
    /// own for kinds of your own, and the default for the rest.
    ///
    /// The default message views show their attachments with it.
    func makeAttachmentView(options: AIMessageAttachmentViewOptions) -> AttachmentViewType

    /// The view type returned by ``makeToolAuthorizationView(options:)``.
    associatedtype ToolAuthorizationViewType: View
    /// Returns what asks the person to sign in when a tool call waits for their account at a
    /// provider, ``AIToolAuthorizationCard`` by default. A view of your own calls the options'
    /// `connect` and `decline`, which open the sign-in and send the person's "not now".
    func makeToolAuthorizationView(options: AIToolAuthorizationViewOptions) -> ToolAuthorizationViewType
}

@available(iOS 15.0, macOS 12.0, *)
public extension AIConversationViewFactory {
    func makeUserMessageView(options: AIUserMessageViewOptions) -> some View {
        AIUserMessageView(viewFactory: self, text: options.text, attachments: options.attachments, onEdit: options.onEdit)
    }

    func makeAssistantMessageView(options: AIAssistantMessageViewOptions) -> some View {
        AIAssistantMessageView(
            viewFactory: self,
            text: options.text,
            isGenerating: options.isGenerating,
            parts: options.parts,
            attachments: options.attachments,
            approver: options.approver,
            reasoningText: options.reasoningText
        )
    }

    @ViewBuilder
    func makeReplyActionsView(options: AIReplyActionsViewOptions) -> some View {
        if let actions = options.actions {
            AIReplyActionsView(text: options.text, actions: actions)
        }
    }

    func makeAttachmentView(options: AIMessageAttachmentViewOptions) -> some View {
        AIMessageAttachmentView(attachment: options.attachment)
    }

    func makeToolAuthorizationView(options: AIToolAuthorizationViewOptions) -> some View {
        AIToolAuthorizationCard(
            authorization: options.authorization,
            state: options.state,
            connect: options.connect,
            decline: options.decline
        )
    }
}

/// The views ``AIConversationView`` shows ``AIMessage``s with when it is given no factory.
@available(iOS 15.0, macOS 12.0, *)
public final class DefaultAIConversationViewFactory: AIConversationViewFactory {
    public static let shared = DefaultAIConversationViewFactory()
}

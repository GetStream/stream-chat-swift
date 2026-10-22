//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The views ``AIConversationView`` shows ``AIMessage``s with.
///
/// Each has a default, so override only the ones you want to change. Under a finished reply
/// there is nothing by default: offer the person what your app does with replies there, such as
/// copying, rating or regenerating them.
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
    /// written out. Empty by default; ``AIReplyActionsView`` is a row of buttons to return.
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
}

public extension AIConversationViewFactory {
    func makeUserMessageView(options: AIUserMessageViewOptions) -> some View {
        AIUserMessageView(viewFactory: self, text: options.text, attachments: options.attachments)
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

    func makeReplyActionsView(options: AIReplyActionsViewOptions) -> some View {
        EmptyView()
    }

    func makeAttachmentView(options: AIMessageAttachmentViewOptions) -> some View {
        AIMessageAttachmentView(attachment: options.attachment)
    }
}

/// The views ``AIConversationView`` shows ``AIMessage``s with when it is given no factory.
public final class DefaultAIConversationViewFactory: AIConversationViewFactory {
    public static let shared = DefaultAIConversationViewFactory()
}

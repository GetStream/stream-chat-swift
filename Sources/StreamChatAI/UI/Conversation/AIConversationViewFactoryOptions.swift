//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What ``AIConversationViewFactory/makeUserMessageView(options:)`` shows.
@available(iOS 15.0, macOS 12.0, *)
public final class AIUserMessageViewOptions {
    /// The message, which is one of the app's own: cast it to read what else it holds. Nil
    /// while the message is on its way.
    public let message: (any AIMessage)?
    /// What the person wrote.
    public let text: String
    /// What they sent with it, such as images and files.
    public let attachments: [AIMessageAttachment]
    /// Puts the message back in the composer to edit, when the list shows an ``AIConversation``
    /// that offers editing and the person can edit it: it is their latest, and the agent isn't
    /// answering.
    public let onEdit: (@MainActor () -> Void)?

    public init(
        message: (any AIMessage)?,
        text: String,
        attachments: [AIMessageAttachment],
        onEdit: (@MainActor () -> Void)? = nil
    ) {
        self.message = message
        self.text = text
        self.attachments = attachments
        self.onEdit = onEdit
    }
}

/// What ``AIConversationViewFactory/makeAssistantMessageView(options:)`` shows.
@available(iOS 15.0, macOS 12.0, *)
public final class AIAssistantMessageViewOptions {
    /// The reply, which is one of the app's own messages: cast it to read what else it holds.
    public let message: any AIMessage
    /// The answer, in Markdown.
    public let text: String
    /// Whether the agent is still writing it.
    public let isGenerating: Bool
    /// The steps the agent took, in order.
    public let parts: [AIMessagePart]
    /// What the agent sent with it, such as images and files.
    public let attachments: [AIMessageAttachment]
    /// The whole of a reasoning step's thinking, when the app has it.
    public let reasoningText: (AIReasoningPart) -> String?
    /// Who answers tool calls' questions on this device.
    public let approver: AIToolApprover?

    public init(
        message: any AIMessage,
        text: String,
        isGenerating: Bool,
        parts: [AIMessagePart],
        attachments: [AIMessageAttachment],
        reasoningText: @escaping (AIReasoningPart) -> String?,
        approver: AIToolApprover?
    ) {
        self.message = message
        self.text = text
        self.isGenerating = isGenerating
        self.parts = parts
        self.attachments = attachments
        self.reasoningText = reasoningText
        self.approver = approver
    }
}

/// What ``AIConversationViewFactory/makeReplyActionsView(options:)`` shows actions for.
@available(iOS 15.0, macOS 12.0, *)
public final class AIReplyActionsViewOptions {
    /// The reply, which is one of the app's own messages: cast it to act on it.
    public let message: any AIMessage
    /// The reply's text, in Markdown, which a reply that answers with generated UI or attachments
    /// may not have.
    public let text: String
    /// Whether it is the latest reply in the conversation, such as the only one an app offers to
    /// regenerate.
    public let isLatestReply: Bool
    /// What the list's ``AIConversation`` offers to do with the reply, as its
    /// ``AIConversation/actions`` allow: rate it, and regenerate it while it is the latest. Nil when
    /// the list doesn't show an ``AIConversation``.
    public let actions: AIReplyActions?

    public init(message: any AIMessage, text: String, isLatestReply: Bool, actions: AIReplyActions? = nil) {
        self.message = message
        self.text = text
        self.isLatestReply = isLatestReply
        self.actions = actions
    }
}

/// What ``AIConversationViewFactory/makeAttachmentView(options:)`` shows.
@available(iOS 15.0, macOS 12.0, *)
public final class AIMessageAttachmentViewOptions {
    /// The attachment.
    public let attachment: AIMessageAttachment
    /// Who sent the message that carries it.
    public let role: AIMessageRole

    public init(attachment: AIMessageAttachment, role: AIMessageRole) {
        self.attachment = attachment
        self.role = role
    }
}

/// What ``AIConversationViewFactory/makeToolAuthorizationView(options:)`` asks the person.
@available(iOS 15.0, macOS 12.0, *)
public final class AIToolAuthorizationViewOptions {
    /// The tool call that waits for the sign-in.
    public let call: AIToolCallPart
    /// The sign-in, such as "Connect Linear".
    public let authorization: AIToolAuthorization
    /// Where the person's answer is.
    public let state: AIToolAuthorizationState
    /// Opens the sign-in page.
    public let connect: @MainActor @Sendable () -> Void
    /// Sends the person's "not now".
    public let decline: @MainActor @Sendable () -> Void

    public init(
        call: AIToolCallPart,
        authorization: AIToolAuthorization,
        state: AIToolAuthorizationState,
        connect: @escaping @MainActor @Sendable () -> Void,
        decline: @escaping @MainActor @Sendable () -> Void
    ) {
        self.call = call
        self.authorization = authorization
        self.state = state
        self.connect = connect
        self.decline = decline
    }
}

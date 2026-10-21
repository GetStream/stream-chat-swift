//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What ``AIConversationViewFactory/makeUserMessageView(options:)`` shows.
public final class AIUserMessageViewOptions {
    /// The message, which is one of the app's own: cast it to read what else it holds. Nil
    /// while the message is on its way.
    public let message: (any AIMessage)?
    /// What the person wrote.
    public let text: String
    /// What they sent with it, such as images and files.
    public let attachments: [AIMessageAttachment]

    public init(message: (any AIMessage)?, text: String, attachments: [AIMessageAttachment]) {
        self.message = message
        self.text = text
        self.attachments = attachments
    }
}

/// What ``AIConversationViewFactory/makeAssistantMessageView(options:)`` shows.
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
public final class AIReplyActionsViewOptions {
    /// The reply, which is one of the app's own messages: cast it to act on it.
    public let message: any AIMessage
    /// The reply's text, in Markdown.
    public let text: String
    /// Whether it is the latest reply in the conversation, such as the only one an app offers to
    /// regenerate.
    public let isLatestReply: Bool

    public init(message: any AIMessage, text: String, isLatestReply: Bool) {
        self.message = message
        self.text = text
        self.isLatestReply = isLatestReply
    }
}

/// What ``AIConversationViewFactory/makeAttachmentView(options:)`` shows.
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

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What ``AIConversationViewFactory/makeUserMessageView(options:)`` shows.
public struct AIUserMessageViewOptions {
    /// What the person wrote.
    public var text: String
    /// What they sent with it, such as images and files.
    public var attachments: [AIMessageAttachment]

    public init(text: String, attachments: [AIMessageAttachment]) {
        self.text = text
        self.attachments = attachments
    }
}

/// What ``AIConversationViewFactory/makeAssistantMessageView(options:)`` shows.
public struct AIAssistantMessageViewOptions {
    /// The answer, in Markdown.
    public var text: String
    /// Whether the agent is still writing it.
    public var isGenerating: Bool
    /// The steps the agent took, in order.
    public var parts: [AIMessagePart]
    /// What the agent sent with it, such as images and files.
    public var attachments: [AIMessageAttachment]
    /// The whole of a reasoning step's thinking, when the app has it.
    public var reasoningText: (AIReasoningPart) -> String?
    /// Who answers tool calls' questions on this device.
    public var approver: AIToolApprover?

    public init(
        text: String,
        isGenerating: Bool,
        parts: [AIMessagePart],
        attachments: [AIMessageAttachment],
        reasoningText: @escaping (AIReasoningPart) -> String?,
        approver: AIToolApprover?
    ) {
        self.text = text
        self.isGenerating = isGenerating
        self.parts = parts
        self.attachments = attachments
        self.reasoningText = reasoningText
        self.approver = approver
    }
}

/// What ``AIConversationViewFactory/makeReplyActionsView(options:)`` shows actions for.
public struct AIReplyActionsViewOptions {
    /// The reply, which is one of the app's own messages: cast it to act on it.
    public var message: any AIMessage
    /// The reply's text, in Markdown.
    public var text: String
    /// Whether it is the latest reply in the conversation, such as the only one an app offers to
    /// regenerate.
    public var isLatestReply: Bool

    public init(message: any AIMessage, text: String, isLatestReply: Bool) {
        self.message = message
        self.text = text
        self.isLatestReply = isLatestReply
    }
}

/// What ``AIConversationViewFactory/makeAttachmentView(options:)`` shows.
public struct AIMessageAttachmentViewOptions {
    /// The attachment.
    public var attachment: AIMessageAttachment
    /// Who sent the message that carries it.
    public var role: AIMessageRole

    public init(attachment: AIMessageAttachment, role: AIMessageRole) {
        self.attachment = attachment
        self.role = role
    }
}

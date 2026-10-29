//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A row of an ``AIConversationView`` of ``AIMessage``s, made by its view factory.
///
/// Rows are equal when what they show is, so a finished message is not laid out again each
/// time a reply streams a little more.
public struct AIConversationEntryView<Message: AIMessage, Factory: AIConversationViewFactory>: View, Equatable {
    let entry: AIConversationEntry<Message>
    let factory: Factory
    let approver: AIToolApprover?
    // Compared rather than the row, whose message and factory belong to the main actor.
    nonisolated let shown: AIConversationEntrySnapshot

    // Whether the reply's answer is still being written out, which its actions wait for so they
    // do not move down with it. `nil` when its view does not say.
    @State private var isWriting: Bool?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Injected(\.aiAppearance.tokens.layout) private var layout

    init(entry: AIConversationEntry<Message>, factory: Factory, approver: AIToolApprover?) {
        self.entry = entry
        self.factory = factory
        self.approver = approver
        shown = AIConversationEntrySnapshot(entry: entry, approver: approver)
    }

    public var body: some View {
        if let message = entry.message {
            if message.role == .user {
                factory.makeUserMessageView(
                    options: AIUserMessageViewOptions(
                        message: message,
                        text: message.text,
                        attachments: entry.sentAttachments.isEmpty ? message.attachments : entry.sentAttachments
                    )
                )
            } else {
                VStack(alignment: .leading, spacing: layout.spacingXs) {
                    factory.makeAssistantMessageView(
                        options: AIAssistantMessageViewOptions(
                            message: message,
                            text: message.text,
                            isGenerating: message.isGenerating,
                            parts: message.parts,
                            attachments: message.attachments,
                            reasoningText: message.reasoningText(for:),
                            approver: approver
                        )
                    )
                    if !message.isGenerating && !message.text.isEmpty && isWriting != true {
                        factory.makeReplyActionsView(
                            options: AIReplyActionsViewOptions(
                                message: message,
                                text: message.text,
                                isLatestReply: entry.isLatestReply
                            )
                        )
                        .transition(.opacity)
                    }
                }
                .onPreferenceChange(AnswerWritingKey.self) { writing in
                    guard writing != isWriting else { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                        isWriting = writing
                    }
                }
            }
        } else if let pending = entry.pending {
            factory.makeUserMessageView(
                options: AIUserMessageViewOptions(message: nil, text: pending.text, attachments: pending.attachments)
            )
        }
    }

    // SwiftUI compares rows of the same message, so what they show is all that can differ.
    public nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.shown == rhs.shown
    }
}

// What a row shows, including each reasoning step's whole thinking, which can grow while the
// message stays the same.
final class AIConversationEntrySnapshot: Equatable, Sendable {
    let isPending: Bool
    let role: AIMessageRole
    let text: String
    let isGenerating: Bool
    let parts: [AIMessagePart]
    let reasoning: [String?]
    let attachments: [AIMessageAttachment]
    let approver: [String]
    let isLatestReply: Bool

    init<Message: AIMessage>(entry: AIConversationEntry<Message>, approver: AIToolApprover?) {
        self.approver = approver.map { [$0.userID, $0.clientID, $0.authorizer?.callbackScheme ?? ""] } ?? []
        isLatestReply = entry.isLatestReply
        if let message = entry.message {
            isPending = false
            role = message.role
            text = message.text
            isGenerating = message.isGenerating
            parts = message.parts
            reasoning = message.parts.map { $0.reasoning.flatMap(message.reasoningText(for:)) }
            attachments = entry.sentAttachments + message.attachments
        } else {
            isPending = true
            role = .user
            text = entry.pending?.text ?? ""
            isGenerating = false
            parts = []
            reasoning = []
            attachments = entry.sentAttachments + (entry.pending?.attachments ?? [])
        }
    }

    static func == (lhs: AIConversationEntrySnapshot, rhs: AIConversationEntrySnapshot) -> Bool {
        lhs.isPending == rhs.isPending
            && lhs.role == rhs.role
            && lhs.text == rhs.text
            && lhs.isGenerating == rhs.isGenerating
            && lhs.parts == rhs.parts
            && lhs.reasoning == rhs.reasoning
            && lhs.attachments == rhs.attachments
            && lhs.approver == rhs.approver
            && lhs.isLatestReply == rhs.isLatestReply
    }
}

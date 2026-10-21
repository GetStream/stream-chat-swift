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
    nonisolated let shown: Shown

    // Whether the reply's answer is still being written out, which its actions wait for so they
    // do not move down with it. `nil` when its view does not say.
    @State private var isWriting: Bool?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Injected(\.aiAppearance.tokens.layout) private var layout

    init(entry: AIConversationEntry<Message>, factory: Factory, approver: AIToolApprover?) {
        self.entry = entry
        self.factory = factory
        self.approver = approver
        shown = Shown(entry: entry, approver: approver)
    }

    public var body: some View {
        switch entry.content {
        case .message(let message):
            switch message.role {
            case .user:
                factory.makeUserMessageView(
                    options: AIUserMessageViewOptions(
                        text: message.text,
                        attachments: entry.sentAttachments.isEmpty ? message.attachments : entry.sentAttachments
                    )
                )
            case .assistant:
                VStack(alignment: .leading, spacing: layout.spacingXs) {
                    factory.makeAssistantMessageView(
                        options: AIAssistantMessageViewOptions(
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
        case .pending(let pending):
            factory.makeUserMessageView(
                options: AIUserMessageViewOptions(text: pending.text, attachments: pending.attachments)
            )
        }
    }

    // SwiftUI compares rows of the same message, so what they show is all that can differ.
    public nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.shown == rhs.shown
    }

    // What a row shows, including each reasoning step's whole thinking, which can grow while
    // the message stays the same.
    struct Shown: Equatable, Sendable {
        var isPending = false
        var role: AIMessageRole = .user
        var text = ""
        var isGenerating = false
        var parts: [AIMessagePart] = []
        var reasoning: [String?] = []
        var attachments: [AIMessageAttachment] = []
        var approver: [String] = []
        var isLatestReply = false

        init(entry: AIConversationEntry<Message>, approver: AIToolApprover?) {
            attachments = entry.sentAttachments
            self.approver = approver.map { [$0.userID, $0.clientID, $0.authorizer?.callbackScheme ?? ""] } ?? []
            isLatestReply = entry.isLatestReply
            switch entry.content {
            case .message(let message):
                role = message.role
                text = message.text
                isGenerating = message.isGenerating
                parts = message.parts
                reasoning = parts.map { $0.reasoning.flatMap(message.reasoningText(for:)) }
                attachments += message.attachments
            case .pending(let pending):
                isPending = true
                text = pending.text
                attachments += pending.attachments
            }
        }
    }
}

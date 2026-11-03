//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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

    init(entry: AIConversationEntry<Message>, factory: Factory, approver: AIToolApprover?) {
        self.entry = entry
        self.factory = factory
        self.approver = approver
        shown = AIConversationEntrySnapshot(entry: entry, approver: approver)
    }

    public var body: some View {
        AIConversationRow<Message, Factory, Never>(entry: entry, factory: factory, approver: approver, generated: nil)
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
    let uiDocument: AIUIDocument?
    let host: ObjectIdentifier?

    init<Message: AIMessage>(entry: AIConversationEntry<Message>, approver: AIToolApprover?, host: AnyObject? = nil) {
        self.approver = approver.map { [$0.userID, $0.clientID, $0.authorizer?.callbackScheme ?? ""] } ?? []
        isLatestReply = entry.isLatestReply
        self.host = host.map(ObjectIdentifier.init)
        if let message = entry.message {
            isPending = false
            role = message.role
            text = message.text
            isGenerating = message.isGenerating
            parts = message.parts
            reasoning = message.parts.map { $0.reasoning.flatMap(message.reasoningText(for:)) }
            attachments = entry.sentAttachments + message.attachments
            uiDocument = message.uiDocument
        } else {
            isPending = true
            role = .user
            text = entry.pending?.text ?? ""
            isGenerating = false
            parts = []
            reasoning = []
            attachments = entry.sentAttachments + (entry.pending?.attachments ?? [])
            uiDocument = nil
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
            && lhs.uiDocument == rhs.uiDocument
            && lhs.host == rhs.host
    }
}

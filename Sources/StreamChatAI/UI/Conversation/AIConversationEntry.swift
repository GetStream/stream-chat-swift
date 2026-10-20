//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A row of an ``AIConversationView`` of ``AIMessage``s: a message, or one the person sent that
/// is on its way.
public struct AIConversationEntry<Message: AIMessage>: Identifiable {
    enum Content {
        case message(Message)
        case pending(AIPendingMessage)
    }

    /// The message's id, or, for the copy of a message that was on its way, that message's.
    public let id: AnyHashable
    let content: Content
    // What the person sent with a message on its way, which its copy shows rather than load
    // it again.
    let sentAttachments: [AIMessageAttachment]
    // Whether it is a reply that ends the conversation, which can be asked for again.
    var isLatestReply = false

    var isFromUser: Bool {
        switch content {
        case .message(let message): message.role == .user
        case .pending: true
        }
    }
}

// Matches the messages the person sent while they were on their way to the copies that
// arrive, so each copy takes over its row.
@MainActor
final class AIPendingMessageTracker {
    // The person's messages there were when each pending message was first seen.
    private var before: [String: Set<AnyHashable>] = [:]
    // The pending message each copy took over, by the copy's id.
    private var copies: [AnyHashable: AIPendingMessage] = [:]
    // The pending message of the last update, whose copy can arrive in the update that stops
    // passing it.
    private var lastPending: AIPendingMessage?

    nonisolated init() { /* Nothing to set up. */ }

    // The rows of a conversation: its messages, apart from replies with nothing to show yet,
    // and a message on its way until its copy arrives.
    func entries<Message: AIMessage>(
        for messages: [Message],
        pending: AIPendingMessage?
    ) -> [AIConversationEntry<Message>] {
        var showsPending = pending != nil
        // A copy that arrives in the update that stops passing its pending message still
        // takes over its row. Only then: a message sent later is not the copy of one that failed.
        if let awaited = pending ?? lastPending {
            let sent = messages.filter { $0.role == .user }.map { AnyHashable($0.id) }
            let known = before[awaited.id] ?? Set(sent)
            before[awaited.id] = known
            if let copy = sent.first(where: { !known.contains($0) }) {
                if copies[copy] == nil {
                    copies[copy] = awaited
                }
                showsPending = false
            }
        }
        lastPending = pending
        var entries = messages.filter { !$0.showsNothing }.map { message in
            let taken = copies[AnyHashable(message.id)]
            return AIConversationEntry(
                id: taken.map { AnyHashable($0.id) } ?? AnyHashable(message.id),
                content: .message(message),
                sentAttachments: taken?.attachments ?? []
            )
        }
        if showsPending, let pending {
            entries.append(AIConversationEntry(id: AnyHashable(pending.id), content: .pending(pending), sentAttachments: []))
        }
        if let last = entries.indices.last, !entries[last].isFromUser {
            entries[last].isLatestReply = true
        }
        return entries
    }

    // Whether the latest message is surely waiting for a reply that shows nothing yet: it is on
    // its way, it is the copy of the one on its way, or its reply is being written but shows
    // nothing. Call it after `entries`, which matches the copies.
    func isAwaitingReply<Message: AIMessage>(in messages: [Message], pending: AIPendingMessage?) -> Bool {
        if let last = messages.last, last.role == .assistant, last.isGenerating, last.showsNothing {
            return true
        }
        guard let pending else { return false }
        guard let copy = copies.first(where: { $0.value.id == pending.id })?.key else { return true }
        return messages.last.map { AnyHashable($0.id) == copy } ?? false
    }
}

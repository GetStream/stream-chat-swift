//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A row of an ``AIConversationView`` of ``AIMessage``s: a message, or one the person sent that
/// is on its way.
public final class AIConversationEntry<Message: AIMessage>: Identifiable {
    /// The message's id, or, for the copy of a message that was on its way, that message's.
    public let id: AnyHashable
    // The message, or nil for a message the person sent that is on its way.
    let message: Message?
    // The message the person sent that is on its way, until its copy arrives.
    let pending: AIPendingMessage?
    // What the person sent with a message on its way, which its copy shows rather than load
    // it again.
    let sentAttachments: [AIMessageAttachment]
    // Whether it is a reply that ends the conversation, which can be asked for again.
    var isLatestReply = false

    init(id: AnyHashable, message: Message, sentAttachments: [AIMessageAttachment]) {
        self.id = id
        self.message = message
        pending = nil
        self.sentAttachments = sentAttachments
    }

    init(pending: AIPendingMessage) {
        id = AnyHashable(pending.id)
        message = nil
        self.pending = pending
        sentAttachments = []
    }

    var isFromUser: Bool {
        message.map { $0.role == .user } ?? true
    }
}

// Matches the messages the person sent while they were on their way to the copies that
// arrive, so each copy takes over its row.
@MainActor
final class AIPendingMessageTracker {
    // The person's messages each pending message's copy cannot be: those there were when it
    // was first seen, and those that arrived since without being its copy, such as older ones.
    private var seen: [String: Set<AnyHashable>] = [:]
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
            let sent = messages.filter { $0.role == .user }
            let ids = Set(sent.map { AnyHashable($0.id) })
            let known = seen[awaited.id] ?? ids
            let matched = copies.first { $0.value.id == awaited.id && ids.contains($0.key) }?.key
            if let copy = matched ?? copy(of: awaited, in: sent, known: known) {
                if copies[copy] == nil {
                    copies[copy] = awaited
                }
                showsPending = false
            } else {
                seen[awaited.id] = known.union(ids)
            }
        }
        lastPending = pending
        var entries = messages.filter { !$0.showsNothing }.map { message in
            let taken = copies[AnyHashable(message.id)]
            return AIConversationEntry(
                id: taken.map { AnyHashable($0.id) } ?? AnyHashable(message.id),
                message: message,
                sentAttachments: taken?.attachments ?? []
            )
        }
        if showsPending, let pending {
            entries.append(AIConversationEntry(pending: pending))
        }
        if let last = entries.indices.last, !entries[last].isFromUser {
            entries[last].isLatestReply = true
        }
        return entries
    }

    // The copy of a message that was on its way: the person's message with its id, when the app
    // knew it. Otherwise their first after those known, which older messages loading above
    // cannot be. With none of theirs known, such as when older messages arrive with it, it is
    // their latest, when that is the only new one or says the same.
    private func copy<Message: AIMessage>(
        of pending: AIPendingMessage,
        in sent: [Message],
        known: Set<AnyHashable>
    ) -> AnyHashable? {
        let ids = sent.map { AnyHashable($0.id) }
        if let exact = ids.first(where: { $0 == AnyHashable(pending.id) }) {
            return exact
        }
        if let lastKnown = ids.lastIndex(where: known.contains) {
            return ids.dropFirst(lastKnown + 1).first
        }
        let new = sent.filter { !known.contains(AnyHashable($0.id)) }
        guard let latest = new.last, new.count == 1 || latest.text == pending.text else { return nil }
        return AnyHashable(latest.id)
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

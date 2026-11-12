//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// A request the person made, from when they make it until its reply starts or another request
// takes its place.
@available(iOS 15.0, macOS 12.0, *)
struct AIConversationExchange<Message: AIMessage> {
    // Where the request is: waiting for its reply, stopped by the person before it started, not
    // sent because the transport failed, or not answered by the agent.
    enum State {
        case waiting
        case stopped
        case failed
        case unanswered
    }

    // Tells it apart from the requests before and after it.
    let id: Int
    let request: AIConversationRequest<Message>
    // The messages there were when it was made, none of which is its reply.
    let known: Set<AnyHashable>
    // The messages it replaces, as they were, which the conversation leaves out while it waits:
    // the reply written again, or the message edited, and those after it.
    let replaced: [AnyHashable: Message]
    // The person's message on its way.
    let pending: AIPendingMessage?
    var state = State.waiting

    init(id: Int, request: AIConversationRequest<Message>, conversation: [Message]) {
        self.id = id
        self.request = request
        known = Set(conversation.map { AnyHashable($0.id) })
        let target = request.message.flatMap { message in
            conversation.firstIndex { AnyHashable($0.id) == AnyHashable(message.id) }
        }
        if let target, request.kind == .regenerate || request.kind == .edit {
            replaced = Dictionary(conversation[target...].map { (AnyHashable($0.id), $0) }, uniquingKeysWith: { $1 })
        } else {
            replaced = [:]
        }
        if request.kind == .regenerate {
            pending = nil
        } else {
            let edited = request.kind == .edit ? request.message?.attachments ?? [] : []
            pending = AIPendingMessage(
                id: request.messageID,
                text: request.text,
                attachments: edited + request.attachments.map { AIMessageAttachment(url: $0) }
            )
        }
    }

    var hasFailed: Bool {
        state == .failed || state == .unanswered
    }

    // The person's message while the conversation shows it: until its reply starts, and for a
    // new message also once it is stopped or failed, since the agent may have it, or `retry()`
    // sends it again. The messages an edit replaces come back instead.
    var shownPending: AIPendingMessage? {
        state == .waiting || request.kind == .message ? pending : nil
    }

    // The latest message when it is the request's reply: a reply that wasn't there, or one the
    // request replaces, once it is written again.
    func reply(in conversation: [Message]) -> Message? {
        guard let last = conversation.last, last.role != .user else { return nil }
        let id = AnyHashable(last.id)
        let isRewritten = replaced[id].map { last.isRewritten(from: $0) } ?? false
        return !known.contains(id) || isRewritten ? last : nil
    }

    // Whether its reply has started: it shows something, or it is already finished.
    func hasReplyStarted(in conversation: [Message]) -> Bool {
        guard let reply = reply(in: conversation) else { return false }
        return !reply.hasEmptyContent || !reply.isGenerating
    }

    // Whether the person's message is in the conversation: one with its id, or one of theirs
    // after the messages there were.
    func hasMessageArrived(in conversation: [Message]) -> Bool {
        if conversation.contains(where: { AnyHashable($0.id) == AnyHashable(request.messageID) }) {
            return true
        }
        let lastKnown = conversation.lastIndex { known.contains(AnyHashable($0.id)) }
        return conversation[(lastKnown.map { $0 + 1 } ?? 0)...].contains { $0.role == .user }
    }

    // What `retry()` sends: the request again, or, when the agent had the person's message but
    // couldn't answer it, a request for its reply, since sending it again would add it twice.
    func retryRequest(in conversation: [Message]) -> AIConversationRequest<Message> {
        guard state == .unanswered, request.kind == .message, hasMessageArrived(in: conversation) else { return request }
        return AIConversationRequest(kind: .regenerate, text: request.text)
    }
}

@available(iOS 15.0, macOS 12.0, *)
private extension AIMessage {
    // Whether a reply is written again since it was `original`: it started anew, or it shows
    // something else.
    func isRewritten(from original: Self) -> Bool {
        (isGenerating && !original.isGenerating)
            || text != original.text
            || parts != original.parts
            || attachments != original.attachments
            || uiDocument != original.uiDocument
    }
}

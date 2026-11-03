//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// A request the person made, from when they make it until its reply starts.
struct AIConversationExchange<Message: AIMessage> {
    // Tells it apart from the requests before and after it.
    let id: Int
    let request: AIConversationRequest<Message>
    // The messages there were when it was made, none of which is its reply.
    let known: Set<AnyHashable>
    // The messages it replaces, which the conversation leaves out until its reply starts: the
    // reply written again, or the message edited, and those after it.
    let replaced: Set<AnyHashable>
    // The person's message on its way, shown until its reply starts.
    let pending: AIPendingMessage?

    init(id: Int, request: AIConversationRequest<Message>, conversation: [Message]) {
        self.id = id
        self.request = request
        known = Set(conversation.map { AnyHashable($0.id) })
        let target = request.message.flatMap { message in
            conversation.firstIndex { AnyHashable($0.id) == AnyHashable(message.id) }
        }
        if let target, request.kind == .regenerate || request.kind == .edit {
            replaced = Set(conversation[target...].map { AnyHashable($0.id) })
        } else {
            replaced = []
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

    // Whether its reply has started: the latest message is a reply that wasn't there, or the
    // reply written again as it is rewritten, and it shows something or is already finished.
    func hasReplyStarted(in conversation: [Message]) -> Bool {
        guard let last = conversation.last, last.role != .user else { return false }
        let id = AnyHashable(last.id)
        let isNew = !known.contains(id)
        let isRewritten = request.kind == .regenerate
            && request.message.map { AnyHashable($0.id) == id } == true
            && last.isGenerating
        guard isNew || isRewritten else { return false }
        return !last.hasEmptyContent || !last.isGenerating
    }
}

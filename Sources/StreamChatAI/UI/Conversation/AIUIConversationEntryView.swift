//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A row of an ``AIConversationView`` of ``AIMessage``s, made by its view factory, whose reply
/// shows the UI the agent generated for it in place of its text, from the renderers of its host.
///
/// Rows are equal when what they show is, so a finished message is not laid out again each
/// time a reply streams a little more.
public struct AIUIConversationEntryView<
    Message: AIMessage,
    Factory: AIConversationViewFactory,
    Renderers: AIUIRenderers
>: View, Equatable {
    let entry: AIConversationEntry<Message>
    let factory: Factory
    let approver: AIToolApprover?
    let host: AIUIHost<Renderers>?
    // Compared rather than the row, whose message, factory and host belong to the main actor.
    nonisolated let shown: AIConversationEntrySnapshot

    init(entry: AIConversationEntry<Message>, factory: Factory, approver: AIToolApprover?, host: AIUIHost<Renderers>?) {
        self.entry = entry
        self.factory = factory
        self.approver = approver
        self.host = host
        shown = AIConversationEntrySnapshot(entry: entry, approver: approver, host: host)
    }

    public var body: some View {
        AIConversationRow(entry: entry, factory: factory, approver: approver, generated: generated)
    }

    // The UI the agent generated for the reply, when one of the host's renderers shows it.
    var generated: (some View)? {
        content.map { $0.generatedUI(isStreaming: entry.message?.uiDocument?.isStreaming == true) }
    }

    private var content: Renderers.Content? {
        guard let message = entry.message, message.role != .user, let host, let document = message.uiDocument else {
            return nil
        }
        return host.content(for: document, messageID: String(describing: message.id))
    }

    // SwiftUI compares rows of the same message, so what they show is all that can differ.
    public nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.shown == rhs.shown
    }
}

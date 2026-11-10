//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A reply's generated UI, from the first of its host's renderers that reads its format: the
/// view that renderer made, with its type. It comes in as it first shows while the agent writes
/// it, and its parts as they show after it (see `aiUIEntrance()`).
///
/// ``AIConversationView`` shows it in place of a reply's text when it is given the host. Showing a
/// reply yourself, show it after ``AIAssistantMessageView`` given no text when ``canShow``, and
/// the reply's text otherwise.
@available(iOS 15.0, macOS 12.0, *)
public struct AIUIView<Renderers: AIUIRendererList>: View {
    let content: Renderers.Content?
    let isStreaming: Bool

    public init(host: AIUIHost<Renderers>, document: AIUIDocument, messageID: String) {
        content = host.content(for: document, messageID: messageID)
        isStreaming = document.isStreaming
    }

    /// Whether it shows the reply's UI rather than its text: one of the host's renderers reads
    /// the document, and shows something of its own for the reply.
    public var canShow: Bool {
        content != nil
    }

    public var body: some View {
        if let content {
            content.generatedUI(isStreaming: isStreaming)
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {
    // A reply's generated UI, as wide as the reply, coming in as it first shows while the agent
    // writes it, and being written while its document is.
    func generatedUI(isStreaming: Bool) -> some View {
        modifier(AIUIEntranceStage(isStreaming: isStreaming))
            .frame(maxWidth: .infinity, alignment: .leading)
            .transformPreference(AnswerWritingKey.self) { writing in
                writing = (writing ?? false) || isStreaming
            }
    }
}

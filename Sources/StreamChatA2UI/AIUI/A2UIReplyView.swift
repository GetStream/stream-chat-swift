//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import SwiftUI

/// A reply's UI: its surfaces, which follow its messages as the agent writes them.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIReplyView: View {
    @ObservedObject var reply: A2UIReply
    let source: String
    let isStreaming: Bool
    let theme: A2UITheme?

    @Injected(\.aiAppearance) private var appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(reply.surfaceIds, id: \.self) { surfaceId in
                A2UISurface(host: reply.processor, surfaceId: surfaceId)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.a2uiTheme, theme ?? A2UITheme(appearance: appearance))
        .onAppear { reply.update(source: source, isStreaming: isStreaming) }
        // One handler for both: `onChange(of:perform:)` runs a closure made with the view's
        // previous values, so a handler per value applies the other one stale when both change
        // at once, and a stale, shorter source starts the surfaces again.
        .onChange(of: Document(source: source, isStreaming: isStreaming)) { document in
            reply.update(source: document.source, isStreaming: document.isStreaming)
        }
    }

    private struct Document: Equatable {
        let source: String
        let isStreaming: Bool
    }
}

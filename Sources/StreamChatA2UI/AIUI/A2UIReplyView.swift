//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A reply's UI: its surfaces, which follow its messages as the agent writes them.
struct A2UIReplyView: View {
    @ObservedObject var reply: A2UIReply
    let source: String
    let isStreaming: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(reply.surfaceIds, id: \.self) { surfaceId in
                A2UISurface(host: reply.processor, surfaceId: surfaceId)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { reply.update(source: source, isStreaming: isStreaming) }
        .onChange(of: source) { source in reply.update(source: source, isStreaming: isStreaming) }
        .onChange(of: isStreaming) { isStreaming in reply.update(source: source, isStreaming: isStreaming) }
    }
}

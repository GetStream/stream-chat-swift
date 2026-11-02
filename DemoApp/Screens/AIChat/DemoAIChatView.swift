//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatAI
import SwiftUI

/// A channel as an AI conversation, with StreamChatAI's `AIChat`. An agent that answers in the
/// channel by the Stream AI backend contract, such as one of Stream's sample backends, replies.
struct DemoAIChatView: View {
    @StateObject private var chat: AIChat<DemoAIChatMessage>

    init(channel: ChatChannelController) {
        _chat = StateObject(wrappedValue: AIChat(transport: DemoAIChatTransport(channel: channel)))
    }

    var body: some View {
        AIConversationView(chat: chat) {
            if chat.status.isAnswering, let activity = chat.activity?.text {
                AITypingIndicatorView(text: activity)
            }
        } emptyContent: {
            Text("Ask the agent in this channel anything.")
                .foregroundStyle(.secondary)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // Over the composer rather than under the latest turn, which an empty
                // conversation doesn't have.
                if let error = chat.error {
                    HStack {
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Try Again") {
                            chat.retry()
                        }
                        .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                AIComposerView(chat: chat)
            }
        }
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct MessageListView: View {
    let chat: Chat
    let messages: [ChatMessage]
    @FocusState private var focusedMessageId: MessageId?
    @State private var isLoadingOlderMessages = false
    @State private var olderMessagesAnchorId: MessageId?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(messages, id: \.id) { message in
                        MessageRow(
                            authorName: message.author.name ?? message.author.id,
                            text: message.text,
                            isFailed: message.localState == .sendingFailed,
                            isFocused: focusedMessageId == message.id
                        )
                        // Focusable rows let the remote move through, and scroll, the message history.
                        .focusable()
                        .focused($focusedMessageId, equals: message.id)
                        .id(message.id)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            // Without it, the focus engine focuses and scrolls to a row near the top.
            .defaultFocus($focusedMessageId, messages.last?.id)
            .onChange(of: focusedMessageId) { _, newFocusedId in
                if let newFocusedId, newFocusedId == messages.first?.id {
                    loadOlderMessages(anchoredAt: newFocusedId)
                }
            }
            .onChange(of: messages.first?.id) { _, newFirstId in
                // Older messages were prepended: keep the message that started loading in view.
                guard let anchorId = olderMessagesAnchorId, newFirstId != anchorId else { return }
                olderMessagesAnchorId = nil
                proxy.scrollTo(anchorId, anchor: .top)
            }
            .onChange(of: messages.last?.id) { _, newLastId in
                guard let newLastId else { return }
                withAnimation {
                    proxy.scrollTo(newLastId, anchor: .bottom)
                }
            }
        }
    }

    private func loadOlderMessages(anchoredAt messageId: MessageId) {
        guard !isLoadingOlderMessages, !chat.state.hasLoadedAllOldestMessages else { return }
        isLoadingOlderMessages = true
        olderMessagesAnchorId = messageId
        Task {
            defer { isLoadingOlderMessages = false }
            try? await chat.loadOlderMessages()
        }
    }
}

private struct MessageRow: View {
    let authorName: String
    let text: String
    let isFailed: Bool
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(authorName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
            if isFailed {
                Text("Failed to send")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isFocused ? Color.primary.opacity(0.25) : Color.clear, in: .rect(cornerRadius: 16))
    }
}

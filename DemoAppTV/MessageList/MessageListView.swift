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
    @State private var photosMessage: ChatMessage?

    var body: some View {
        let dayStartIds = dayStartIds
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(messages, id: \.id) { message in
                        let photos = message.imageAttachments
                        VStack(spacing: 16) {
                            if dayStartIds.contains(message.id) {
                                Text(Self.dayFormatter.string(from: message.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            MessageRow(
                                authorName: message.author.name ?? message.author.id,
                                createdAt: message.createdAt,
                                text: message.text,
                                photos: photos,
                                isFailed: message.localState == .sendingFailed,
                                isFocused: focusedMessageId == message.id
                            )
                            // Focusable rows let the remote move through, and scroll, the message history.
                            .focusable()
                            .focused($focusedMessageId, equals: message.id)
                            .onTapGesture {
                                if !photos.isEmpty { photosMessage = message }
                            }
                            .accessibilityAddTraits(photos.isEmpty ? [] : .isButton)
                            .id(message.id)
                        }
                    }
                }
            }
            .fullScreenCover(item: $photosMessage) { message in
                PhotoViewer(photos: message.imageAttachments)
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

    private var dayStartIds: Set<MessageId> {
        var ids = Set(messages.prefix(1).map(\.id))
        for (previous, message) in zip(messages, messages.dropFirst())
            where !Calendar.current.isDate(previous.createdAt, inSameDayAs: message.createdAt) {
            ids.insert(message.id)
        }
        return ids
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

private struct MessageRow: View {
    let authorName: String
    let createdAt: Date
    let text: String
    let photos: [ChatMessageImageAttachment]
    let isFailed: Bool
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                Text(authorName)
                Text(createdAt, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !photos.isEmpty {
                MessagePhotosView(photos: photos)
            }
            if !text.isEmpty {
                Text(text)
            }
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

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct ChannelView: View {
    let client: ChatClient
    let cid: ChannelId
    @State private var chat: Chat?

    var body: some View {
        Group {
            if let chat {
                ChannelContentView(chat: chat, currentUserId: client.currentUserId)
            } else {
                ProgressView()
            }
        }
        .task {
            guard chat == nil else { return }
            let chat = client.makeChat(for: cid, messageOrdering: .bottomToTop)
            self.chat = chat
            try? await chat.get(watch: true)
        }
    }
}

private struct ChannelContentView: View {
    let chat: Chat
    let currentUserId: UserId?
    @ObservedObject private var state: ChatState

    init(chat: Chat, currentUserId: UserId?) {
        self.chat = chat
        self.currentUserId = currentUserId
        _state = ObservedObject(wrappedValue: chat.state)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if let channel = state.channel {
                ChannelHeaderView(
                    name: channel.displayName(currentUserId: currentUserId),
                    avatarURL: channel.avatarURL(currentUserId: currentUserId),
                    memberCount: channel.memberCount
                )
            }
            MessageListView(chat: chat, messages: state.messages)
            ComposerView(chat: chat)
        }
    }
}

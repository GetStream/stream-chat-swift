//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct ChannelListView: View {
    let client: ChatClient
    let channelList: ChannelList
    @ObservedObject private var state: ChannelListState
    @State private var isLoadingMoreChannels = false
    @State private var errorMessage: String?

    init(client: ChatClient, channelList: ChannelList) {
        self.client = client
        self.channelList = channelList
        _state = ObservedObject(wrappedValue: channelList.state)
    }

    var body: some View {
        NavigationStack {
            List(state.channels) { channel in
                NavigationLink(value: channel.cid) {
                    ChannelRow(
                        name: channel.displayName(currentUserId: client.currentUserId),
                        avatarURL: channel.avatarURL(currentUserId: client.currentUserId),
                        previewText: channel.latestMessages.first?.text
                    )
                }
                .onAppear {
                    if channel.cid == state.channels.last?.cid {
                        loadMoreChannels()
                    }
                }
            }
            .navigationTitle("Channels")
            .navigationDestination(for: ChannelId.self) { cid in
                ChannelView(client: client, cid: cid)
            }
            .overlay {
                if state.channels.isEmpty, let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load Channels", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") {
                            Task { await loadChannels() }
                        }
                    }
                }
            }
            .task {
                await loadChannels()
            }
        }
    }

    private func loadChannels() async {
        errorMessage = nil
        do {
            try await channelList.get()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadMoreChannels() {
        guard !isLoadingMoreChannels else { return }
        isLoadingMoreChannels = true
        Task {
            defer { isLoadingMoreChannels = false }
            _ = try? await channelList.loadMoreChannels()
        }
    }
}

private struct ChannelRow: View {
    let name: String
    let avatarURL: URL?
    let previewText: String?

    var body: some View {
        HStack(spacing: 24) {
            AvatarView(url: avatarURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .lineLimit(1)
                if let previewText {
                    Text(previewText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

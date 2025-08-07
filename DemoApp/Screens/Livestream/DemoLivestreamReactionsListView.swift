//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI

struct DemoLivestreamReactionsListView: View {
    let message: ChatMessage
    let controller: LivestreamChannelController
    @Environment(\.presentationMode) private var presentationMode

    @State private var reactions: [ChatMessageReaction] = []
    @State private var isLoading = false
    @State private var hasLoadedAll = false
    @State private var errorMessage: String?

    private let pageSize = 25

    var body: some View {
        NavigationView {
            VStack {
                if reactions.isEmpty && isLoading {
                    ProgressView("Loading reactions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No reactions yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(reactions, id: \.self) { reaction in
                            ReactionRowView(reaction: reaction)
                        }

                        if !hasLoadedAll {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear {
                                        loadMoreReactions()
                                    }
                                Spacer()
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Reactions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            loadInitialReactions()
        }
    }

    private func loadInitialReactions() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        controller.loadReactions(for: message.id, limit: pageSize, offset: 0) { result in
            isLoading = false
            switch result {
            case .success(let newReactions):
                reactions = newReactions
                hasLoadedAll = newReactions.count < pageSize
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadMoreReactions() {
        guard !isLoading && !hasLoadedAll else { return }
        isLoading = true

        controller.loadReactions(for: message.id, limit: pageSize, offset: reactions.count) { result in
            isLoading = false
            switch result {
            case .success(let newReactions):
                reactions.append(contentsOf: newReactions)
                hasLoadedAll = newReactions.count < pageSize
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct ReactionRowView: View {
    let reaction: ChatMessageReaction

    var body: some View {
        HStack(spacing: 12) {
            if #available(iOS 15.0, *) {
                AsyncImage(url: reaction.author.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(reaction.author.name?.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reaction.author.name ?? "Unknown User")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(formatReactionDate(reaction.createdAt))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let reactionAppearance = Appearance.default.images.availableReactions[reaction.type] {
                if #available(iOS 15.0, *) {
                    Image(uiImage: reactionAppearance.largeIcon)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color(Appearance.default.colorPalette.accentPrimary))
                }
            } else {
                Text(Appearance.default.images.availableReactionPushEmojis[reaction.type] ?? "👍")
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 4)
    }

    private func formatReactionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

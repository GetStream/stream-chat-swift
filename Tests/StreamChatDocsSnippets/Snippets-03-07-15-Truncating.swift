//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/truncate-channel/

import StreamChat

@MainActor struct Snippets_03_07_15_Truncating {
    var chatClient: ChatClient!

    func truncateAChannel() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        // The Swift SDK defaults to hardDelete: true, which permanently deletes the messages
        controller.truncateChannel()

        // Hide the messages instead of deleting them permanently
        controller.truncateChannel(hardDelete: false)

        // Or with parameters:
        controller.truncateChannel(
          skipPush: true,
          hardDelete: true,
          systemMessage: "Dear Everyone. The channel has been truncated."
        )
    }

    func truncateAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        // The Swift SDK defaults to hardDelete: true, which permanently deletes the messages
        try await chat.truncate()

        // Hide the messages instead of deleting them permanently
        try await chat.truncate(hardDelete: false)

        // Or with parameters:
        try await chat.truncate(
          systemMessage: "Dear Everyone. The channel has been truncated.",
          hardDelete: true,
          skipPush: true
        )
    }
}

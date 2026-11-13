//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/pinning-channels/

import StreamChat

@MainActor struct Snippets_03_07_09_Pinning {
    var chatClient: ChatClient!
    var currentUserId: UserId!

    func pinAChannel() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        // Pin the channel for the current user.
        channelController.pin { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            }
        }

        // Query all the pinned channels.
        let channelListController = chatClient.channelListController(
            query: ChannelListQuery(
                filter: .and([
                    .containMembers(userIds: [currentUserId]),
                    .equal(.pinned, to: true)
                ])
            )
        )
        channelListController.synchronize { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            } else {
                let pinnedChannels = channelListController.channels
                suppressUnusedWarning(pinnedChannels)
            }
        }

        // Unpin the channel for the current user.
        channelController.unpin { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            }
        }
    }

    func pinAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        // Pin the channel for the current user
        try await chat.pin()

        // Query all the pinned channels.
        let channelList = chatClient.makeChannelList(
            with: ChannelListQuery(
                filter: .and([
                    .containMembers(userIds: [currentUserId]),
                    .equal(.pinned, to: true)
                ])
            )
        )
        try await channelList.get()
        let pinnedChannels = channelList.state.channels
        suppressUnusedWarning(pinnedChannels)

        // Unpin the channel for the current user.
        try await chat.unpin()
    }
}

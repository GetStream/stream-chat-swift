//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/archiving-channels/

import StreamChat

@MainActor struct Snippets_03_07_08_Archiving {
    var chatClient: ChatClient!
    var currentUserId: UserId!

    func archiveAChannel() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        // Archive the channel for the current user.
        channelController.archive { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            }
        }

        // Query all the archived channels.
        let channelListController = chatClient.channelListController(
            query: ChannelListQuery(
                filter: .and([
                    .containMembers(userIds: [currentUserId]),
                    .equal(.archived, to: true)
                ])
            )
        )
        channelListController.synchronize { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            } else {
                let archivedChannels = channelListController.channels
                suppressUnusedWarning(archivedChannels)
            }
        }

        // Unarchive the channel for the current user.
        channelController.unarchive { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            }
        }
    }

    func archiveAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        // Archive the channel for the current user.
        try await chat.archive()

        // Query all the archived channels.
        let channelList = chatClient.makeChannelList(
            with: ChannelListQuery(
                filter: .and([
                    .containMembers(userIds: [currentUserId]),
                    .equal(.archived, to: true)
                ])
            )
        )
        try await channelList.get()
        let archivedChannels = channelList.state.channels
        suppressUnusedWarning(archivedChannels)

        // Unarchive the channel for the current user.
        try await chat.unarchive()
    }
}

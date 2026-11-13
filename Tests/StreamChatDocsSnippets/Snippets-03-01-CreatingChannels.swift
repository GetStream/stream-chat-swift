//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/creating-channels/

import StreamChat

struct Snippets_03_01_CreatingChannels {
    var chatClient: ChatClient!

    func creatingAChannelUsingAChannelID() throws {
        /// 1: Create a `ChannelId` that represents the channel you want to create.
        let channelId = ChannelId(type: .messaging, id: "general")

        /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
        let channelController = try chatClient.channelController(
          createChannelWithId: channelId,
          name: "Awesome channel about traveling"
        )

        /// 3: Call `ChatChannelController.synchronize` to create the channel.
        channelController.synchronize { error in
          if let error = error {
            /// 4: Handle possible errors
            print(error)
          }
        }
    }

    func distinctChannels() throws {
        /// 1: Use the `ChatClient` to create a `ChatChannelController` with a list of user ids
        let channelController = try chatClient.channelController(
          createDirectMessageChannelWith: ["thierry", "tomasso"],
          extraData: [:]
        )

        /// 2: Call `ChatChannelController.synchronize` to create the channel.
        channelController.synchronize { error in
          if let error = error {
            /// 4: Handle possible errors
            print(error)
          }
        }
    }

    func watchingChannels() {
        // Channels are watched automatically when they're synchronized.

        /// 1: Create a `ChannelId` that represents the channel you want to watch.
        let channelId = ChannelId(type: .messaging, id: "general")

        /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
        let channelController = chatClient.channelController(for: channelId)

        /// 3: Call `ChatChannelController.synchronize` to watch the channel.
        channelController.synchronize { error in
          if let error = error {
            /// 4: Handle possible errors
            print(error)
          }
        }
    }
}

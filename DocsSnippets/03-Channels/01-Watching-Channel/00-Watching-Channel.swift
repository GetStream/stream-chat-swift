// LINK: https://getstream.io/chat/docs/ios-swift/watch_channel/?preview=1&language=swift#to-start-watching-a-channel

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_watching_channel() {
    // > import StreamChat
    
    /// Channels are watched automatically when they're synchronized.

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

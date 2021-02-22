// LINK: https://getstream.io/chat/docs/ios-swift/?language=swift#channels

import StreamChat

private var chatClient: ChatClient!

func snippet_introduction_channels() {
    /// 1: Create a `ChannelId` that represents the channel you want to create.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
    let channelController = chatClient.channelController(for: channelId)
    
    /// 3: Call `ChatChannelController.synchronize` to create the channel.
    channelController.synchronize { error in
        if let error = error {
            /// 4: Handle possible errors
            print(error)
        }
    }
}

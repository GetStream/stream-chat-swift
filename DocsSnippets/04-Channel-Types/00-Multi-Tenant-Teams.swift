// LINK: https://getstream.io/chat/docs/ios-swift/multi_tenant_chat/?preview=1&language=swift#channel-team

import StreamChat

private var chatClient: ChatClient!

func snippet_channel_types_multi_tenant_teams() throws {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to create.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
    let channelController = try chatClient.channelController(
        createChannelWithId: channelId,
        name: "Channel Name",
        imageURL: nil,
        team: "red",
        extraData: [:]
    )

    /// 3: Call `ChatChannelController.synchronize` to create the channel.
    channelController.synchronize { error in
        if let error = error {
            /// 4: Handle possible errors
            print(error)
        }
    }
}

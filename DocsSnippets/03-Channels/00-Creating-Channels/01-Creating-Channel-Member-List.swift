// LINK: https://getstream.io/chat/docs/ios-swift/creating_channels/?preview=1&language=swift#2.-creating-a-channel-for-a-list-of-members

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_creating_channel_member_list() throws {
    // > import StreamChat
    
    /// 1: Use the `ChatClient` to create a `ChatChannelController` with a list of user ids
    let channelController = try chatClient.channelController(
        createDirectMessageChannelWith: ["john"],
        isCurrentUserMember: true,
        name: nil,
        imageURL: nil,
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

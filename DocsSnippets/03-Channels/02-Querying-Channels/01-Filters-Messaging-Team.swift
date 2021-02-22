// LINK: https://getstream.io/chat/docs/ios-swift/query_channels/?preview=1&language=swift#messaging-and-team

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_querying_channels_filters_messaging_team() {
    // > import StreamChat
    
    let currentUserChannels = chatClient.channelListController(
        query: .init(
            filter: .containMembers(userIds: [chatClient.currentUserId!])
        )
    )

    currentUserChannels.synchronize()

    // or

    let thierryChannels = chatClient.channelListController(
        query: .init(
            filter: .containMembers(userIds: ["thierry"])
        )
    )

    thierryChannels.synchronize()
}

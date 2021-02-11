// LINK: https://getstream.io/chat/docs/ios-swift/query_channels/?preview=1&language=swift#support

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_querying_channels_filters_support() {
    // > import StreamChat
    
    let channels = chatClient.channelListController(
        query: .init(
            filter: .and([.equal("agent_id", to: chatClient.currentUserId!), .in("status", values: ["pending", "open", "new"])])
        )
    )

    channels.synchronize()
}

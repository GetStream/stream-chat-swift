// LINK: https://getstream.io/chat/docs/ios-swift/channel_invites/?language=swift#query-for-accepted-invites

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_query_accepted_invites() {
    // > import StreamChat

    let controller = chatClient.channelListController(
        query: .init(
            filter: .equal("invite", to: "accepted")
        )
    )

    controller.synchronize { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // access channels
            print(controller.channels)
            
            // load more if needed
            controller.loadNextChannels(limit: 10) { _ in
                // handle error / access channels
            }
        }
    }
}

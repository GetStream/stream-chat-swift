// LINK: https://getstream.io/chat/docs/ios-swift/channel_invites/?language=swift#query-for-rejected-invites

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_query_rejected_invite() {
    // > import StreamChat

    let controller = chatClient.channelListController(
        query: .init(
            filter: .equal("invite", to: "rejected")
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

// LINK: https://getstream.io/chat/docs/ios-swift/query_channels/?preview=1&language=swift#pagination

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_querying_channels_pagination() {
    // > import StreamChat
    
    let controller = chatClient.channelListController(
        query: .init(
            filter: .containMembers(userIds: ["thierry"]),
            pageSize: 10
        )
    )

    // Get the first 10 channels
    controller.synchronize { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // Access channels
            print(controller.channels)
            
            // Get the next 10 channels
            controller.loadNextChannels { error in
                // handle error / access channels
                print(error ?? controller.channels)
            }
        }
    }
}

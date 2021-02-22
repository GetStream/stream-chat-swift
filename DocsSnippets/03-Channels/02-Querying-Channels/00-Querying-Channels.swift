// LINK: https://getstream.io/chat/docs/ios-swift/query_channels/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_querying_channels() {
    // > import StreamChat
    
    let controller = chatClient.channelListController(
        query: .init(
            filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: ["thierry"])]),
            sort: [.init(key: .lastMessageAt, isAscending: false)],
            pageSize: 10
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

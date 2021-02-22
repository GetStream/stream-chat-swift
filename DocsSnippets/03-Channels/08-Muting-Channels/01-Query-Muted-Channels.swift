// LINK: https://getstream.io/chat/docs/ios-swift/muting_channels/?preview=1&language=swift#query-muted-channels

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_muting_channels_remove_channel_mute() {
    // > import StreamChat

    let controller = chatClient.channelListController(
        query: .init(
            filter: .equal("muted", to: true)
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
            controller.loadNextChannels { error in
                // handle error / access channels
                print(error ?? controller.channels)
            }
        }
    }
}

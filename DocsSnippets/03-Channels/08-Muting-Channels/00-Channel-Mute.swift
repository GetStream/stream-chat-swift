// LINK: https://getstream.io/chat/docs/ios-swift/muting_channels/?preview=1&language=swift#channel-mute

import StreamChat

private var chatClient: ChatClient!

func snippet_channelsmuting_channels_channel_mute() {
    // > import Stream Chat

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    // mute channel
    controller.muteChannel { error in
        if let error = error {
            // handle error
            print(error)
        }
    }

    // unmute channel
    controller.unmuteChannel { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}

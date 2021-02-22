// LINK: https://getstream.io/chat/docs/ios-swift/muting_channels/?preview=1&language=swift#remove-a-channel-mute

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_muting_channels_channel_remove_channel_mute() {
    // > import Stream Chat

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    // unmute channel
    controller.unmuteChannel { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}

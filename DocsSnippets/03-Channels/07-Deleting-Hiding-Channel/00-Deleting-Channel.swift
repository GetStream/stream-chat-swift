// LINK: https://getstream.io/chat/docs/ios-swift/channel_delete/?preview=1&language=swift#deleting-a-channel

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_deleting_hiding_channel_deleting_channel() {
    // > import Stream Chat

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    controller.deleteChannel { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}

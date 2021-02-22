// LINK: https://getstream.io/chat/docs/ios-swift/channel_delete/?preview=1&language=swift#hiding-a-channel

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_deleting_hiding_channel_hiding_channel() {
    // > import Stream Chat

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    // hide channel
    controller.hideChannel { error in
        if let error = error {
            // handle error
            print(error)
        }
    }

    // show channel
    controller.showChannel { error in
        if let error = error {
            // handle error
            print(error)
        }
    }

    // hide channel and clear message history
    controller.hideChannel(clearHistory: true) { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}

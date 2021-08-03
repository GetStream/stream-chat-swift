// LINK: https://getstream.io/chat/docs/ios-swift/channel_update/?preview=1&language=swift#full-update-(overwrite)

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_channel_updating_channel_full_update() {
    // > import Stream Chat

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    controller.updateChannel(name: "My special channel", imageURL: nil, team: nil, extraData: [:]) { error in
        if let error = error {
            // handle errors
            print(error)
        }
    }
}

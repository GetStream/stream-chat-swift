// LINK: https://getstream.io/chat/docs/ios-swift/channel_update/?preview=1&language=swift#full-update-(overwrite)

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_channel_changing_channel_members() {
    // > import Stream Chat

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    controller.addMembers(userIds: ["thierry", "josh"])
    controller.removeMembers(userIds: ["tommaso"])
}

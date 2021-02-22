// LINK: https://getstream.io/chat/docs/ios-swift/multi_tenant_chat/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_overview_send_message() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to send a message to.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
    let channelController = chatClient.channelController(for: channelId)

    /// 3: Call `ChatChannelController.createNewMessage` to create the message.
    channelController.createNewMessage(text: "Hello") { result in
        switch result {
        case let .success(messageId):
            print(messageId)
        case let .failure(error):
            print(error)
        }
    }
}

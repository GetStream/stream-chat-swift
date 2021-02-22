// LINK: https://getstream.io/chat/docs/ios-swift/file_uploads/?preview=1&language=javascript

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_file_uploads() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to send a message to.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
    let channelController = chatClient.channelController(for: channelId)

    /// 3: Call `ChatChannelController.createNewMessage` to create the message.
    channelController.createNewMessage(
        text: "Hello",
        attachments: [ChatMessageAttachmentSeed(localURL: URL(string: "./my_image.png")!, fileName: "my_image.png", type: .image)]
    ) { result in
        switch result {
        case let .success(messageId):
            print(messageId)
        case let .failure(error):
            print(error)
        }
    }
}

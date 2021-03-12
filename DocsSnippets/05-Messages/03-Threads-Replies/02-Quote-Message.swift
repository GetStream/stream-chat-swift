// LINK: https://getstream.io/chat/docs/ios-swift/threads/?language=swift&preview=1#quote-message

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_threads_replies_quote_message() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to send a message to.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
    let channelController = chatClient.channelController(for: channelId)

    /// 3: Call `ChatChannelController.createNewMessage` with
    /// `quotedMessageId` to create the message that quotes another message.
    channelController.createNewMessage(text: "Hello!", quotedMessageId: "message-id") { result in
        switch result {
        case let .success(messageId):
            print(messageId)
        case let .failure(error):
            print(error)
        }
    }
}

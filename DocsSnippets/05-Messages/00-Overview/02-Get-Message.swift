// LINK: https://getstream.io/chat/docs/ios-swift/send_message/?preview=1&language=swift#get-a-message

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_overview_get_message() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to get a message from.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Create a `MessageId` that represents the message you want to get.
    let messageId = "message-id"

    /// 3: Use the `ChatClient` to create a `ChatMessageController` with the `ChannelId` and message id.
    let messageController = chatClient.messageController(cid: channelId, messageId: messageId)
    
    /// 4: Call `ChatMessageController.synchronize` to get the message.
    messageController.synchronize { error in
        // handle possible errors / access message
        print(error ?? messageController.message!)
    }
}

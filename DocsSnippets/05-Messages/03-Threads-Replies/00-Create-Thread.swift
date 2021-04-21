// LINK: https://getstream.io/chat/docs/ios-swift/threads/?language=swift&preview=1

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_threads_replies_create_thread() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to get a message from.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Create a `MessageId` that represents the message you want to get.
    let messageId = "message-id"

    /// 3: Use the `ChatClient` to create a `ChatMessageController` with the `ChannelId` and message id.
    let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

    /// 4: Call `ChatMessageController.createNewReply` to start a thread.
    messageController.createNewReply(text: "What's up?")
}

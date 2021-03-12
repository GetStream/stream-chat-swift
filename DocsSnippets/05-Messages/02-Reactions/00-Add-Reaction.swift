// LINK: https://getstream.io/chat/docs/ios-swift/send_reaction/?language=swift&preview=1

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_reactions_add_reaction() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to get a message from.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Create a `MessageId` that represents the message you want to get.
    let messageId = "message-id"

    /// 3: Use the `ChatClient` to create a `ChatMessageController` with the `ChannelId` and message id.
    let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

    /// 4: Call `ChatMessageController.addReaction` to add the reaction.
    messageController.addReaction("like") { error in
        print(error ?? "message liked")
    }
}

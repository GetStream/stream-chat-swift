// LINK: https://getstream.io/chat/docs/ios-swift/threads/?language=swift&preview=1#thread-pagination

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_threads_replies_thread_pagination() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to get a message from.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Create a `MessageId` that represents the message you want to get.
    let messageId = "message-id"

    /// 3: Use the `ChatClient` to create a `ChatMessageController` with the `ChannelId` and message id.
    let controller = chatClient.messageController(cid: channelId, messageId: messageId)

    /// 4: Call `ChatMessageController.loadNextReplies` to get the replies.
    controller.loadNextReplies(limit: 25) { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // access messages
            print(controller.replies)
            
            controller.loadNextReplies(limit: 25) { error in
                // handle error / access messages
                print(error ?? controller.replies)
            }
        }
    }
}

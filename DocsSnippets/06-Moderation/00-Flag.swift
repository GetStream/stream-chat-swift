// LINK: https://getstream.io/chat/docs/ios-swift/send_message/?preview=1&language=swift#get-a-message

import StreamChat

private var chatClient: ChatClient!

func snippet_moderation_flag() {
    // > import StreamChat

    // FLAG/UNFLAG MESSAGES

    /// 1: Create a `ChannelId` that represents the channel you want to get a message from.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Create a `MessageId` that represents the message you want to flag.
    let messageId = "message-id"

    /// 3: Use the `ChatClient` to create a `ChatMessageController` with the `ChannelId` and message id.
    let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

    /// 4: Call `ChatMessageController.flag` to flag the message.
    messageController.flag { error in
        // handle possible errors / access message
        print(error ?? "message flagged")
        
        /// 5: Call `ChatMessageController.unflag` to unflag the message.
        messageController.unflag { error in
            print(error ?? "message unflagged")
        }
    }

    // FLAG/UNFLAG USERS

    let userController = chatClient.userController(userId: "another_user")

    /// 1: Call `ChatUserController.flag` to flag the user.
    userController.flag { error in
        // handle possible errors
        print(error ?? "user flagged")
        
        /// 2: Call `ChatUserController.unflag` to unflag the user.
        userController.unflag { error in
            print(error ?? "user unflagged")
        }
    }
}

// LINK: https://getstream.io/chat/docs/ios-swift/send_message/?preview=1&language=swift#get-a-message

import StreamChat

private var chatClient: ChatClient!

func snippet_moderation_mutes() {
    // > import StreamChat

    let userController = chatClient.userController(userId: "another_user")

    /// 1: Call `ChatUserController.mute` to mute the user.
    userController.mute { error in
        // handle possible errors
        print(error ?? "user muted")
        
        /// 2: Call `ChatUserController.unmute` to unmute the user.
        userController.unmute { error in
            print(error ?? "user unmuted")
        }
    }
}

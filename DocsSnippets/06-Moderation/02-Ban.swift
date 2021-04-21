// LINK: https://getstream.io/chat/docs/ios-swift/moderation/?language=swift&preview=1#ban

import StreamChat

private var chatClient: ChatClient!

func snippet_moderation_ban() {
    // > import StreamChat

    /// 1: Create a `ChannelId` that represents the channel you want to ban a user from.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Create a `ChatChannelMemberController` to make operations on a channel member.
    let controller = chatClient.memberController(userId: "another_user", in: channelId)

    /// 3: Call `ChatChannelMemberController.ban` to ban the user from the channel.
    controller.ban { error in
        // handle possible errors
        print(error ?? "user banned")
        
        /// 4: Call `ChatUserController.unmute` to unmute the user.
        controller.unban { error in
            print(error ?? "user unmuted")
        }
    }
}

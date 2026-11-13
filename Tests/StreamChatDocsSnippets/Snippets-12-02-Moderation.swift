//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/moderation/

import StreamChat

struct Snippets_12_02_Moderation {
    var channelId: ChannelId!
    var chatClient: ChatClient!
    var client: ChatClient!
    var messageController: ChatMessageController!
    var messageId: MessageId!
    var userToBlock: ChatUser!
    var userToUnblock: ChatUser!

    func givingModeratorsMorePermissions() {
        let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "channel-id"))

        // Add a member with moderator role
        channelController.addMembers([
          MemberInfo(userId: "james_bond", channelRole: .moderator)
        ]) { error in
          // ...
        }
    }

    func slowMode() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        channelController.enableSlowMode(cooldownDuration: 10)

        channelController.disableSlowMode()
    }

    func flag() {
        let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

        messageController.flag { error in
          print(error ?? "message flagged")
        }

        // Flag a user
        let userController = chatClient.userController(userId: "another_user")
        userController.flag { error in
          print(error ?? "user flagged")
        }
    }

    func flag2() {
        // flag with a reason
        messageController.flag(reason: "spammy_user")
    }

    func block() {
        chatClient.userController(userId: "user-to-block").block { error in
          // ...
        }
    }

    func blockUser() {
        chatClient.userController(userId: userToBlock.id).block { error in /* ... */ }
    }

    func unblockUser() {
        chatClient.userController(userId: userToUnblock.id).unblock { error in /* ... */ }
    }

    func listOfBlockedUsers() {
        chatClient.currentUserController().loadBlockedUsers { result in
          switch result {
          case .success(let blockedUsers):
            // Handle success
            suppressUnusedWarning(blockedUsers)
            break
          case .failure(let error):
            // Handle error
            suppressUnusedWarning(error)
            break
          }
        }
    }
}

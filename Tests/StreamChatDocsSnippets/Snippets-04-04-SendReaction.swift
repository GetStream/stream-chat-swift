//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/send-reaction/

import StreamChat

struct Snippets_04_04_SendReaction {
    var chatClient: ChatClient!
    var messageController: ChatMessageController!
    var messageId: MessageId!
    var userId: UserId!

    func sendingAReaction() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let messageId = "message-id"
        let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

        // Add a reaction
        messageController.addReaction("like") { error in
          // Handle error
        }
    }

    func removingAReaction() {
        messageController.deleteReaction("like") { error in
          // Handle error
        }
    }

    func paginatingReactions() {
        // Load first 10 reactions
        messageController.loadReactions(limit: 10, offset: 0) { result in
          let loadedReactions = try? result.get()
          suppressUnusedWarning(loadedReactions)
        }

        // Load reactions 11-20
        messageController.loadReactions(limit: 10, offset: 10) { result in
          let loadedReactions = try? result.get()
          suppressUnusedWarning(loadedReactions)
        }
    }

    func queryingReactions() {
        // Query reactions by type
        let likesController = chatClient.reactionListController(
          query: ReactionListQuery(messageId: messageId, filter: .equal(.reactionType, to: "like"))
        )
        likesController.synchronize { error in
          print(likesController.reactions)
        }

        // Query reactions by user
        let userReactionsController = chatClient.reactionListController(
          query: ReactionListQuery(messageId: messageId, filter: .equal(.authorId, to: userId))
        )
        userReactionsController.synchronize { error in
          print(userReactionsController.reactions)
        }

        // Paginate results
        let reactionListController = chatClient.reactionListController(for: messageId)
        reactionListController.synchronize { error in
          guard error == nil else { return }
          reactionListController.loadMoreReactions(limit: 5) { error in
            print(reactionListController.reactions)
          }
        }
    }

    func cumulativeReactions() {
        messageController.addReaction("clap", score: 5) { error in
          // Handle error
        }
    }
}

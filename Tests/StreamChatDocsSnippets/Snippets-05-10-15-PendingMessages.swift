//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/pending-messages/

import StreamChat

struct Snippets_05_10_15_PendingMessages {
    var client: ChatClient!

    func queryingPendingMessages() {
        // To retrieve a single message
        let messageController = client.messageController(
          cid: ChannelId(type: .messaging, id: "channel_id"),
          messageId: "pending_message_id"
        )
        messageController.synchronize { error in
          let message = messageController.message
          suppressUnusedWarning(message)
        }
    }

    func queryChannels() {
        // Querying multiple channels returns each channel's pending messages
        let query = ChannelListQuery(
          filter: .and([
            .equal(.type, to: .messaging),
            .containMembers(userIds: ["thierry"])
          ]),
          sort: [.init(key: .lastMessageAt, isAscending: false)]
        )
        let channelListController = client.channelListController(query: query)
        channelListController.synchronize { error in
          // Pending messages of the first channel
          let pendingMessages = channelListController.channels.first?.pendingMessages
          suppressUnusedWarning(pendingMessages)
        }
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/pinned-messages/

import Foundation
import StreamChat

struct Snippets_04_05_PinnedMessages {
    var channelController: ChatChannelController!
    var client: ChatClient!

    func pinningAndUnpinningMessages() {
        let messageController = client.messageController(
          cid: .init(type: .messaging, id: "general"),
          messageId: "message-id"
        )

        // Pin message for 120 seconds
        messageController.pin(.expirationTime(120))

        // Pin to a specific date
        let pinExpirationDate = Calendar.current.date(byAdding: DateComponents(day: 7), to: Date())!
        messageController.pin(.expirationDate(pinExpirationDate))

        // Unpin message
        messageController.unpin()
    }

    func retrievingPinnedMessages() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        channelController.synchronize() { error in
          if error == nil {
            let pinnedMessages = channelController.channel?.pinnedMessages
            suppressUnusedWarning(pinnedMessages)
          }
        }
    }

    func paginatingPinnedMessages() {
        channelController.loadPinnedMessages(
          pageSize: 10,
          sorting: [.init(key: .pinnedAt, isAscending: false)],
          pagination: .earlier(Date(), inclusive: true)) { result in
            switch result {
            case .success(let pinnedMessages):
              print(pinnedMessages)

              // Next page using the ID of the last message on this page
              guard let lastPinnedMessageId = pinnedMessages.last?.id else { return }
              channelController.loadPinnedMessages(
                pageSize: 10,
                sorting: [.init(key: .pinnedAt, isAscending: false)],
                pagination: .before(lastPinnedMessageId, inclusive: false)) { result in
                  // Handle result
                }
            case .failure(let error):
              // Handle error
              print(error)
            }
          }
    }
}

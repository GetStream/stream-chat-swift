//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/channel-pagination/

import StreamChat

@MainActor struct Snippets_03_05_ChannelPagination {
    var chatClient: ChatClient!

    func messagePagination() async throws {
        let messageId: MessageId = "123"
        let channelId = ChannelId(type: .messaging, id: "general")
        let controller = chatClient.channelController(for: channelId)

        // Load messages around a specific message (id_around)
        controller.loadPageAroundMessageId(messageId) { error in
          if let error = error {
            print(error)
          } else {
            print(controller.messages)

            // Load newer messages (id_gt)
            controller.loadNextMessages(limit: 10) { error in
              print(error ?? controller.messages)

              // Load older messages (id_lt)
              controller.loadPreviousMessages(limit: 10) { error in
                print(error ?? controller.messages)
              }
            }
          }
        }

        // Alternative: Use Chat for more granular control
        let chat = chatClient.makeChat(for: channelId)

        // Each call updates chat.state.messages
        // Messages newer than ID (id_gt)
        try await chat.loadMessages(after: messageId, limit: 10)
        print(chat.state.messages)

        // Messages older than ID (id_lt)
        try await chat.loadMessages(before: messageId, limit: 10)
        print(chat.state.messages)

        // Messages around ID (id_around)
        try await chat.loadMessages(around: messageId, limit: 10)
        print(chat.state.messages)
    }

    func memberAndWatcherPagination() {
        let channelId = ChannelId(type: .messaging, id: "general")

        // Members: the controller sets the offset from the members it has already loaded
        let memberListController = chatClient.memberListController(
          query: .init(cid: channelId, pageSize: 20)
        )
        memberListController.synchronize { error in
          guard error == nil else { return }
          // Load the next page of members
          memberListController.loadNextMembers(limit: 20) { error in
            print(memberListController.members)
          }
        }

        // Watchers: the controller sets the offset from the watchers it has already loaded
        let watcherListController = chatClient.watcherListController(
          query: .init(cid: channelId, pagination: Pagination(pageSize: 20))
        )
        watcherListController.synchronize { error in
          guard error == nil else { return }
          // Load the next page of watchers
          watcherListController.loadNextWatchers(limit: 20) { error in
            print(watcherListController.watchers)
          }
        }
    }
}

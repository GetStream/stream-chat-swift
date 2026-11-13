//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/search/

import StreamChat

struct Snippets_04_06_Search {
    var client: ChatClient!

    func searchingMessages() {
        let controller = client.messageSearchController()

        // Search for messages containing text
        let textQuery = MessageSearchQuery(
          channelFilter: .containMembers(userIds: ["john"]),
          messageFilter: .queryText("supercalifragilisticexpialidocious"),
          pageSize: 10
        )

        // Search with message filters
        let filteredQuery = MessageSearchQuery(
          channelFilter: .containMembers(userIds: ["john"]),
          messageFilter: .and([.autocomplete(.text, text: "super"), .withAttachments]),
          pageSize: 10
        )

        // Each search replaces the controller's previous results
        controller.search(query: textQuery) { error in
          if let error = error {
            // Handle error
            print(error)
            return
          }
          let results = controller.messages
          suppressUnusedWarning(results)

          controller.search(query: filteredQuery) { error in
            guard error == nil else { return }
            let filtered = controller.messages
            suppressUnusedWarning(filtered)
          }
        }
    }

    func pagination() {
        let controller = client.messageSearchController()
        let query = MessageSearchQuery(
          channelFilter: .equal(.cid, to: ChannelId(type: .messaging, id: "my-channel")),
          messageFilter: .autocomplete(.text, text: "supercali"),
          sort: [.init(key: .updatedAt, isAscending: true)],
          pageSize: 10
        )

        // First page with custom sorting
        controller.search(query: query) { error in
          guard error == nil else { return }

          // Next page: when the query has a sort, the controller uses the `next` cursor
          // of the previous response and appends the results to `controller.messages`
          controller.loadNextMessages(limit: 10) { error in
            print(controller.messages)
          }
        }
    }
}

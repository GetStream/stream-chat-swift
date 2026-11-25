//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/query-members/

import StreamChat

struct Snippets_03_04_QueryMembers {
    var chatClient: ChatClient!

    func queryingMembers() {
        // Query by user name
        let controller = chatClient.memberListController(
          query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal(.name, to: "tommaso"))
        )

        controller.synchronize { error in
          print(error ?? controller.members)
        }

        // Autocomplete members by user name
        let autocompleteController = chatClient.memberListController(
          query: .init(cid: .init(type: .messaging, id: "general"), filter: .autocomplete(.name, text: "tom"))
        )
        autocompleteController.synchronize()

        // Query all members
        let allMembersController = chatClient.memberListController(
          query: .init(cid: .init(type: .messaging, id: "general"), filter: .none)
        )
        allMembersController.synchronize()
    }

    func paginatingChannelMembers() {
        let memberListController = chatClient.memberListController(
          query: .init(
            cid: .init(type: .messaging, id: "general"),
            sort: [.init(key: .createdAt, isAscending: true)]
          )
        )

        memberListController.synchronize() { error in
          if error == nil {
            print(memberListController.members)
          }
        }

        // Paginate channel members
        memberListController.loadNextMembers(limit: 10) { error in
          print(error ?? memberListController.members)
        }
    }
}

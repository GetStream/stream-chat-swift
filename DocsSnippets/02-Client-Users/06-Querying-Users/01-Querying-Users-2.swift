// LINK: https://getstream.io/chat/docs/ios-swift/query_users/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_querying_users_2() {
    // > import StreamChat
    
    let controller = chatClient.userListController(
        query: .init(
            filter: .in(.id, values: ["john", "jack", "jessie"]),
            sort: [.init(key: .lastActivityAt, isAscending: false)]
        )
    )

    controller.synchronize { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // access users
            print(controller.users)
            
            // load more if needed
            controller.loadNextUsers(limit: 10) { _ in
                // handle error / access users
            }
        }
    }
}

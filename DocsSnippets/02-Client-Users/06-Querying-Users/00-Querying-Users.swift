// LINK: https://getstream.io/chat/docs/ios-swift/query_users/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_querying_users() {
    // > import StreamChat
    
    let controller = chatClient.userListController(
        query: .init(filter: .in(.id, values: ["john", "jack", "jessie"]))
    )

    controller.synchronize { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // access users
            print(controller.users)
        }
    }
}

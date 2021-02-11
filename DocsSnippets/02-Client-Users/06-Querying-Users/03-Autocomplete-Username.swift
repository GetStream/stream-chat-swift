// LINK: https://getstream.io/chat/docs/ios-swift/query_users/?preview=1&language=swift#1.-by-username

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_querying_users_autocomplete_username() {
    // > import StreamChat
    
    let controller = chatClient.userListController(
        query: .init(filter: .autocomplete(.name, text: "ro"))
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

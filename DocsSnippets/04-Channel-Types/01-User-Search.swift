// LINK: https://getstream.io/chat/docs/ios-swift/multi_tenant_chat/?preview=1&language=swift#user-search

import StreamChat

private var chatClient: ChatClient!

func snippet_channel_types_user_search() {
    // > import StreamChat

    let controller = chatClient.userListController(
        query: .init(filter: .in("teams", values: ["blue"]))
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

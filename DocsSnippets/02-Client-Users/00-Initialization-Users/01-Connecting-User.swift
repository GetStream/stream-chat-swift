// LINK: https://getstream.io/chat/docs/ios-swift/init_and_users/?preview=1&language=swift#connecting-the-user

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_initialization_users_connecting_user() {
    // > import StreamChat

    // This call is only needed if you've disconnected before.
    chatClient.connectionController().connect { error in
        if let error = error {
            // handle possible errors
            print(error)
        }
    }
}

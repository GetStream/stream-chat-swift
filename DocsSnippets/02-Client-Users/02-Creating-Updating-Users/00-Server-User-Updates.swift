// LINK: https://getstream.io/chat/docs/ios-swift/update_users/?preview=1&language=swift#server-side-user-updates-(batch)

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_creating_updating_users_server_user_updates() {
    // > import StreamChat

    chatClient.currentUserController().updateUserData(
        name: "Bob",
        imageURL: URL(string: "https://bob.com/image.png")!,
        userExtraData: nil
    ) { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}

// LINK: https://getstream.io/chat/docs/ios-swift/logout/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_logging_out() {
    // > import StreamChat
    
    // It's impossible to log out a user because the Client instance must always have a user assigned.
    
    // However, you can simulate this behavior by A: destroying the client instance, or:
    
    // B: Setting the current user as anonymous
    
    chatClient.tokenProvider = .anonymous
    chatClient.currentUserController().reloadUserIfNeeded()
    
    // C: Disconnecting the client
    
    chatClient.connectionController().disconnect()

    // when you want to reconnect

    chatClient.connectionController().connect { error in
        if error == nil {
            // connection successful
        }
    }
}

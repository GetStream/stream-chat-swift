// LINK: https://getstream.io/chat/docs/ios-swift/init_and_users/?preview=1&language=swift#websocket-connections

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_initialization_users_websocket_connections() {
    // > import StreamChat

    chatClient.connectionController().disconnect()
}

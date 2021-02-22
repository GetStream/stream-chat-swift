// LINK: https://getstream.io/chat/docs/ios-swift/ios_client_setup/?preview=1&language=swift#connecting-disconnecting

import StreamChat

private var chatClient: ChatClient!

func snippet_ux_client_setup_disconnecting() {
    // > import UIKit
    // > import StreamChat

    chatClient.connectionController().disconnect()
}

// LINK: https://getstream.io/chat/docs/ios-swift/ios_logging/?preview=1&language=swift#examples:

import NotificationCenter
import StreamChat
import StreamChatUI

private var chatClient: ChatClient!

func snippet_ux_logging_only_errors() {
    // > import StreamChat

    LogConfig.level = .error
}

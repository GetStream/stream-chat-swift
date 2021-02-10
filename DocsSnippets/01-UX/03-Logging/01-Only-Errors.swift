//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import NotificationCenter
import StreamChat
import StreamChatUI

private var chatClient: ChatClient!

func snippet_ux_logging_only_errors() {
    // > import StreamChat

    LogConfig.level = .error
}

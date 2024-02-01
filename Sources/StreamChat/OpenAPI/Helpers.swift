//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamChatChannelStateResponse {
    var toResponseFields: StreamChatChannelStateResponseFields {
        StreamChatChannelStateResponseFields(
            members: members,
            messages: messages,
            pinnedMessages: pinnedMessages,
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            watcherCount: watcherCount,
            pendingMessages: pendingMessages,
            read: read,
            watchers: watchers,
            channel: channel,
            membership: membership
        )
    }
}

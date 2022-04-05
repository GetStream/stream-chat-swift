//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChannelUnreadCount {
    static func mock(
        messages: Int,
        mentioningMessages: Int = 0,
        silentMessages: Int = 0,
        threadReplies: Int = 0
    ) -> Self {
        .init(
            messages: messages,
            mentioningMessages: mentioningMessages,
            silentMessages: silentMessages,
            threadReplies: threadReplies
        )
    }
}

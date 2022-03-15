//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChannelUnreadCount {
    static func mock(messages: Int, mentionedMessages: Int = 0) -> Self {
        .init(messages: messages, mentionedMessages: mentionedMessages)
    }
}

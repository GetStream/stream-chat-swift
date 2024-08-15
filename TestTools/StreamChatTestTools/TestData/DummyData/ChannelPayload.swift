//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelPayload {
    /// Returns dummy channel payload with the given values.
    static func dummy(
        channel: ChannelDetailPayload = .dummy(),
        watchers: [UserPayload] = [],
        members: [MemberPayload] = [],
        membership: MemberPayload? = nil,
        messages: [MessagePayload] = [],
        pendingMessages: [MessagePayload] = [],
        pinnedMessages: [MessagePayload] = [],
        channelReads: [ChannelReadPayload] = [],
        isHidden: Bool? = nil
    ) -> Self {
        .init(
            channel: channel,
            watcherCount: watchers.count,
            watchers: watchers,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            channelReads: channelReads,
            isHidden: isHidden
        )
    }
}

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
            pinnedMessages: pinnedMessages,
            channelReads: channelReads,
            isHidden: isHidden
        )
    }
}

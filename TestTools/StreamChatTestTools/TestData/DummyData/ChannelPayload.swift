//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelPayload {
    /// Returns dummy channel payload with the given values.
    static func dummy(
        channel: ChannelDetailPayload = .dummy(),
        watcherCount: Int? = nil,
        watchers: [UserPayload] = [],
        members: [MemberPayload] = [],
        membership: MemberPayload? = nil,
        messages: [MessagePayload] = [],
        pendingMessages: [MessagePayload] = [],
        pinnedMessages: [MessagePayload] = [],
        channelReads: [ChannelReadPayload] = [],
        isHidden: Bool? = nil,
        draft: DraftPayload? = nil,
        activeLiveLocations: [SharedLocationPayload] = [],
        pushPreference: PushPreferencePayload? = nil
    ) -> Self {
        .init(
            channel: channel,
            watcherCount: watcherCount ?? watchers.count,
            watchers: watchers,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            channelReads: channelReads,
            isHidden: isHidden,
            draft: draft,
            activeLiveLocations: activeLiveLocations,
            pushPreference: pushPreference
        )
    }
}

extension ChannelReadPayload {
    init(
        user: UserPayload,
        lastReadAt: Date,
        lastReadMessageId: MessageId? = nil,
        unreadMessagesCount: Int
    ) {
        self.init(
            user: user,
            lastReadAt: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            unreadMessagesCount: unreadMessagesCount,
            lastDeliveredAt: nil,
            lastDeliveredMessageId: nil
        )
    }
}

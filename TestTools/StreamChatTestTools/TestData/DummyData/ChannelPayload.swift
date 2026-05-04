//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    ) -> ChannelPayload {
        _ = pushPreference
        return ChannelStateResponseFields(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            hidden: isHidden,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages.map { PendingMessageResponse(message: $0) },
            pinnedMessages: pinnedMessages,
            read: channelReads,
            threads: [],
            watcherCount: watcherCount ?? watchers.count,
            watchers: watchers
        )
    }
}

extension ChannelReadPayload {
    convenience init(
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

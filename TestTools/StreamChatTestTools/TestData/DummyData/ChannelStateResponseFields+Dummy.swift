//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelStateResponseFields {
    /// Returns dummy channel payload with the given values.
    static func dummy(
        channel: ChannelResponse = .dummy(),
        watcherCount: Int? = nil,
        watchers: [UserResponse] = [],
        members: [ChannelMemberResponse] = [],
        membership: ChannelMemberResponse? = nil,
        messages: [MessageResponse] = [],
        pendingMessages: [MessageResponse] = [],
        pinnedMessages: [MessageResponse] = [],
        channelReads: [ReadStateResponse] = [],
        isHidden: Bool? = nil,
        draft: DraftResponse? = nil,
        activeLiveLocations: [SharedLocationResponseData] = [],
        pushPreference: PushPreferencesResponse? = nil
    ) -> ChannelStateResponseFields {
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

extension ReadStateResponse {
    static func dummy(
        lastDeliveredAt: Date? = nil,
        lastDeliveredMessageId: MessageId? = nil,
        lastRead: Date = .unique,
        lastReadMessageId: MessageId? = nil,
        unreadMessages: Int = 0,
        user: UserResponse = .dummy(userId: .unique)
    ) -> ReadStateResponse {
        .init(
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId,
            lastRead: lastRead,
            lastReadMessageId: lastReadMessageId,
            unreadMessages: unreadMessages,
            user: user
        )
    }
}

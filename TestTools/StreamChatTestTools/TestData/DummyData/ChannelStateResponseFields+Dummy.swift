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
    convenience init(
        user: UserResponse,
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

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
        activeLiveLocations: [SharedLocation] = [],
        pushPreference: PushPreference? = nil
    ) -> Self {
        .init(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            hidden: isHidden,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages.map { PendingMessageResponse(message: $0) },
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreference,
            read: channelReads,
            watcherCount: watcherCount ?? watchers.count,
            watchers: watchers
        )
    }
}

extension ChannelPayload {
    convenience init(
        channel: ChannelDetailPayload,
        watcherCount: Int? = nil,
        watchers: [UserPayload]? = nil,
        members: [MemberPayload],
        membership: MemberPayload? = nil,
        messages: [MessagePayload],
        pendingMessages: [MessagePayload]? = nil,
        pinnedMessages: [MessagePayload],
        channelReads: [ChannelReadPayload],
        isHidden: Bool? = nil,
        draft: DraftPayload? = nil,
        activeLiveLocations: [SharedLocation] = [],
        pushPreference: PushPreference? = nil
    ) {
        self.init(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            hidden: isHidden,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages?.map { PendingMessageResponse(message: $0) },
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreference,
            read: channelReads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}

extension ChannelReadPayload {
    convenience init(
        user: UserPayload,
        lastReadAt: Date,
        lastReadMessageId: MessageId? = nil,
        unreadMessagesCount: Int,
        lastDeliveredAt: Date? = nil,
        lastDeliveredMessageId: MessageId? = nil
    ) {
        self.init(
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId,
            lastRead: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            unreadMessages: unreadMessagesCount,
            user: user
        )
    }
}

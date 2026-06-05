//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UnreadCountPayload {
    static var dummy: Self {
        .init(
            channels: Int.random(in: 0...Int.max),
            messages: Int.random(in: 0...Int.max),
            threads: Int.random(in: 0...Int.max)
        )
    }
}

extension UnreadCount {
    static var dummy: Self {
        .init(
            channels: Int.random(in: 0...Int.max),
            messages: Int.random(in: 0...Int.max),
            threads: Int.random(in: 0...Int.max)
        )
    }
}

extension WrappedUnreadCountsResponse {
    static func dummy(
        channelType: [UnreadCountsChannelType] = [],
        channels: [UnreadCountsChannel] = [],
        duration: String = "",
        threads: [UnreadCountsThread] = [],
        totalUnreadCount: Int = 0,
        totalUnreadCountByTeam: [TeamId: Int]? = nil,
        totalUnreadThreadsCount: Int = 0
    ) -> WrappedUnreadCountsResponse {
        .init(
            channelType: channelType,
            channels: channels,
            duration: duration,
            threads: threads,
            totalUnreadCount: totalUnreadCount,
            totalUnreadCountByTeam: totalUnreadCountByTeam,
            totalUnreadThreadsCount: totalUnreadThreadsCount
        )
    }
}

extension UnreadCountsChannel {
    static func dummy(
        channelId: ChannelId = .unique,
        lastRead: Date = Date(timeIntervalSince1970: 0),
        unreadCount: Int = 0
    ) -> UnreadCountsChannel {
        .init(channelId: channelId.rawValue, lastRead: lastRead, unreadCount: unreadCount)
    }
}

extension UnreadCountsChannelType {
    static func dummy(
        channelCount: Int = 0,
        channelType: ChannelType = .messaging,
        unreadCount: Int = 0
    ) -> UnreadCountsChannelType {
        .init(channelCount: channelCount, channelType: channelType.rawValue, unreadCount: unreadCount)
    }
}

extension UnreadCountsThread {
    static func dummy(
        lastRead: Date = Date(timeIntervalSince1970: 0),
        lastReadMessageId: MessageId = "",
        parentMessageId: MessageId = .unique,
        unreadCount: Int = 0
    ) -> UnreadCountsThread {
        .init(
            lastRead: lastRead,
            lastReadMessageId: lastReadMessageId,
            parentMessageId: parentMessageId,
            unreadCount: unreadCount
        )
    }
}

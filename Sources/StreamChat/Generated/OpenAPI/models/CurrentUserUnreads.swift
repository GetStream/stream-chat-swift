//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CurrentUserUnreads: Sendable, Decodable {
    public let channelType: [UnreadChannelByType]
    public let channels: [UnreadChannel]
    public let threads: [UnreadThread]
    public let totalUnreadCount: Int
    public let totalUnreadCountByTeam: [String: Int]?
    public let totalUnreadThreadsCount: Int

    init(
        channelType: [UnreadChannelByType],
        channels: [UnreadChannel],
        threads: [UnreadThread],
        totalUnreadCount: Int,
        totalUnreadCountByTeam: [String: Int]? = nil,
        totalUnreadThreadsCount: Int
    ) {
        self.channelType = channelType
        self.channels = channels
        self.threads = threads
        self.totalUnreadCount = totalUnreadCount
        self.totalUnreadCountByTeam = totalUnreadCountByTeam
        self.totalUnreadThreadsCount = totalUnreadThreadsCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        case channels
        case threads
        case totalUnreadCount = "total_unread_count"
        case totalUnreadCountByTeam = "total_unread_count_by_team"
        case totalUnreadThreadsCount = "total_unread_threads_count"
    }
}

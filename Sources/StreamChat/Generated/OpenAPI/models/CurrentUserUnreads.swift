//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The total unread information from the current user.
public final class CurrentUserUnreads: Sendable, Decodable {
    /// The unread information per channel type.
    public let channelType: [UnreadChannelByType]
    /// The unread information per channel.
    public let channels: [UnreadChannel]
    /// The unread information per thread.
    public let threads: [UnreadThread]
    /// The total number of unread messages.
    public let totalUnreadCount: Int
    /// The total number of unread messages grouped by team.
    public let totalUnreadCountByTeam: [String: Int]?
    /// The total number of unread threads.
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

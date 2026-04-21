//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class WrappedUnreadCountsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelType: [UnreadCountsChannelType]
    var channels: [UnreadCountsChannel]
    /// Duration of the request in milliseconds
    var duration: String
    var threads: [UnreadCountsThread]
    var totalUnreadCount: Int
    var totalUnreadCountByTeam: [String: Int]?
    var totalUnreadThreadsCount: Int

    init(channelType: [UnreadCountsChannelType], channels: [UnreadCountsChannel], duration: String, threads: [UnreadCountsThread], totalUnreadCount: Int, totalUnreadCountByTeam: [String: Int]? = nil, totalUnreadThreadsCount: Int) {
        self.channelType = channelType
        self.channels = channels
        self.duration = duration
        self.threads = threads
        self.totalUnreadCount = totalUnreadCount
        self.totalUnreadCountByTeam = totalUnreadCountByTeam
        self.totalUnreadThreadsCount = totalUnreadThreadsCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        case channels
        case duration
        case threads
        case totalUnreadCount = "total_unread_count"
        case totalUnreadCountByTeam = "total_unread_count_by_team"
        case totalUnreadThreadsCount = "total_unread_threads_count"
    }

    static func == (lhs: WrappedUnreadCountsResponse, rhs: WrappedUnreadCountsResponse) -> Bool {
        lhs.channelType == rhs.channelType &&
            lhs.channels == rhs.channels &&
            lhs.duration == rhs.duration &&
            lhs.threads == rhs.threads &&
            lhs.totalUnreadCount == rhs.totalUnreadCount &&
            lhs.totalUnreadCountByTeam == rhs.totalUnreadCountByTeam &&
            lhs.totalUnreadThreadsCount == rhs.totalUnreadThreadsCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelType)
        hasher.combine(channels)
        hasher.combine(duration)
        hasher.combine(threads)
        hasher.combine(totalUnreadCount)
        hasher.combine(totalUnreadCountByTeam)
        hasher.combine(totalUnreadThreadsCount)
    }
}

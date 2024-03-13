//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct WrappedUnreadCountsResponse: Codable, Hashable {
    public var duration: String
    public var totalUnreadCount: Int
    public var totalUnreadThreadsCount: Int
    public var channelType: [UnreadCountsChannelType]
    public var channels: [UnreadCountsChannel]
    public var threads: [UnreadCountsThread]

    public init(duration: String, totalUnreadCount: Int, totalUnreadThreadsCount: Int, channelType: [UnreadCountsChannelType], channels: [UnreadCountsChannel], threads: [UnreadCountsThread]) {
        self.duration = duration
        self.totalUnreadCount = totalUnreadCount
        self.totalUnreadThreadsCount = totalUnreadThreadsCount
        self.channelType = channelType
        self.channels = channels
        self.threads = threads
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case totalUnreadCount = "total_unread_count"
        case totalUnreadThreadsCount = "total_unread_threads_count"
        case channelType = "channel_type"
        case channels
        case threads
    }
}

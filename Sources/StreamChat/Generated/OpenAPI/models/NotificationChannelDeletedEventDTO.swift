//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationChannelDeletedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The CID of the channel which was deleted
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let groupedUnreadChannels: [String: Int]?
    /// The total number of unread messages
    let totalUnreadCount: Int?
    /// The type of event: "notification.channel_deleted" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int?

    init(
        channel: ChannelDetailPayload,
        cid: ChannelId,
        createdAt: Date,
        groupedUnreadChannels: [String: Int]? = nil,
        totalUnreadCount: Int? = nil,
        type: String = "notification.channel_deleted",
        unreadChannels: Int? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.groupedUnreadChannels = groupedUnreadChannels
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case cid
        case createdAt = "created_at"
        case groupedUnreadChannels = "grouped_unread_channels"
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
    }
}

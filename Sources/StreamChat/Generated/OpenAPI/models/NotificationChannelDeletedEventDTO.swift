//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel is successfully deleted.
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.groupedUnreadChannels = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .groupedUnreadChannels
        )
        self.totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
    }
}

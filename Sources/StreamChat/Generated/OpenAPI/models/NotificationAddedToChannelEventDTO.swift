//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sent to a user when they are added to a channel (as a personal notification to update their channel list).
final class NotificationAddedToChannelEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// Date/time of creation
    let createdAt: Date
    let groupedUnreadChannels: [String: Int]?
    let member: MemberPayload
    /// The total number of unread messages
    let totalUnreadCount: Int?
    /// The type of event: "notification.added_to_channel" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int?

    init(
        channel: ChannelDetailPayload,
        createdAt: Date,
        groupedUnreadChannels: [String: Int]? = nil,
        member: MemberPayload,
        totalUnreadCount: Int? = nil,
        type: String = "notification.added_to_channel",
        unreadChannels: Int? = nil
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.groupedUnreadChannels = groupedUnreadChannels
        self.member = member
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.groupedUnreadChannels = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .groupedUnreadChannels
        )
        self.member = try container.decode(MemberPayload.self, forKey: .member)
        self.totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
    }
}

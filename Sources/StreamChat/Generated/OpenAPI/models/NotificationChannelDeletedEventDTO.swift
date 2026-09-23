//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationChannelDeletedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel which was deleted
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel which was deleted
    let channelType: String?
    /// The CID of the channel which was deleted
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let groupedUnreadChannels: [String: Int]?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    /// The total number of unread messages
    let totalUnreadCount: Int?
    /// The type of event: "notification.channel_deleted" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int?
    /// The number of unread messages in the channel
    let unreadCount: Int?

    init(
        channel: ChannelDetailPayload,
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        groupedUnreadChannels: [String: Int]? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        totalUnreadCount: Int? = nil,
        type: String = "notification.channel_deleted",
        unreadChannels: Int? = nil,
        unreadCount: Int? = nil
    ) {
        self.channel = channel
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.groupedUnreadChannels = groupedUnreadChannels
        self.receivedAt = receivedAt
        self.team = team
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelCustom = "channel_custom"
        case channelId = "channel_id"
        case channelMemberCount = "channel_member_count"
        case channelMessageCount = "channel_message_count"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case groupedUnreadChannels = "grouped_unread_channels"
        case receivedAt = "received_at"
        case team
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationChannelDeletedEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel which was deleted
    var channelId: String?
    /// The number of members in the channel
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel which was deleted
    var channelType: String?
    /// The CID of the channel which was deleted
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var groupedUnreadChannels: [String: Int]?
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The total number of unread messages
    var totalUnreadCount: Int?
    /// The type of event: "notification.channel_deleted" in this case
    var type: String = "notification.channel_deleted"
    /// The number of channels with unread messages
    var unreadChannels: Int?
    /// The number of unread messages in the channel
    var unreadCount: Int?

    init(channel: ChannelResponse, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], groupedUnreadChannels: [String: Int]? = nil, receivedAt: Date? = nil, team: String? = nil, totalUnreadCount: Int? = nil, unreadChannels: Int? = nil, unreadCount: Int? = nil) {
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

    static func == (lhs: NotificationChannelDeletedEventOpenAPI, rhs: NotificationChannelDeletedEventOpenAPI) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.groupedUnreadChannels == rhs.groupedUnreadChannels &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.totalUnreadCount == rhs.totalUnreadCount &&
            lhs.type == rhs.type &&
            lhs.unreadChannels == rhs.unreadChannels &&
            lhs.unreadCount == rhs.unreadCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(channelCustom)
        hasher.combine(channelId)
        hasher.combine(channelMemberCount)
        hasher.combine(channelMessageCount)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(groupedUnreadChannels)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(totalUnreadCount)
        hasher.combine(type)
        hasher.combine(unreadChannels)
        hasher.combine(unreadCount)
    }
}

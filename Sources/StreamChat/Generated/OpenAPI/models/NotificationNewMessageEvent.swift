//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationNewMessageEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was sent
    var channelId: String?
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel where the message was sent
    var channelType: String?
    /// The CID of the channel where the message was sent
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var groupedUnreadChannels: [String: Int]?
    var message: MessageResponse
    var messageId: String
    var parentAuthor: String?
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The participants of the thread
    var threadParticipants: [UserResponseCommonFields]?
    var totalUnreadCount: Int?
    /// The type of event: "notification.message_new" in this case
    var type: String = "notification.message_new"
    var unreadChannels: Int?
    var unreadCount: Int?
    /// The number of watchers
    var watcherCount: Int

    init(channel: ChannelResponse, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], groupedUnreadChannels: [String: Int]? = nil, message: MessageResponse, messageId: String, parentAuthor: String? = nil, receivedAt: Date? = nil, team: String? = nil, threadParticipants: [UserResponseCommonFields]? = nil, totalUnreadCount: Int? = nil, unreadChannels: Int? = nil, unreadCount: Int? = nil, watcherCount: Int) {
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
        self.message = message
        self.messageId = messageId
        self.parentAuthor = parentAuthor
        self.receivedAt = receivedAt
        self.team = team
        self.threadParticipants = threadParticipants
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.watcherCount = watcherCount
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
        case message
        case messageId = "message_id"
        case parentAuthor = "parent_author"
        case receivedAt = "received_at"
        case team
        case threadParticipants = "thread_participants"
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case watcherCount = "watcher_count"
    }

    static func == (lhs: NotificationNewMessageEvent, rhs: NotificationNewMessageEvent) -> Bool {
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
            lhs.message == rhs.message &&
            lhs.messageId == rhs.messageId &&
            lhs.parentAuthor == rhs.parentAuthor &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.threadParticipants == rhs.threadParticipants &&
            lhs.totalUnreadCount == rhs.totalUnreadCount &&
            lhs.type == rhs.type &&
            lhs.unreadChannels == rhs.unreadChannels &&
            lhs.unreadCount == rhs.unreadCount &&
            lhs.watcherCount == rhs.watcherCount
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
        hasher.combine(message)
        hasher.combine(messageId)
        hasher.combine(parentAuthor)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(threadParticipants)
        hasher.combine(totalUnreadCount)
        hasher.combine(type)
        hasher.combine(unreadChannels)
        hasher.combine(unreadCount)
        hasher.combine(watcherCount)
    }
}

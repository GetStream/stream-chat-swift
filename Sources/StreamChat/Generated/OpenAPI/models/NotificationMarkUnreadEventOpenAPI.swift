//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationMarkUnreadEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel which was marked as unread
    var channelId: String?
    /// The number of members in the channel
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel which was marked as unread
    var channelType: String?
    /// The CID of the channel which was marked as unread
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The ID of the first unread message
    var firstUnreadMessageId: String?
    var groupedUnreadChannels: [String: Int]?
    /// The time when the channel/thread was marked as unread
    var lastReadAt: Date?
    /// The ID of the last read message
    var lastReadMessageId: String?
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The ID of the thread which was marked as unread
    var threadId: String?
    /// The total number of unread messages
    var totalUnreadCount: Int?
    /// The type of event: "notification.mark_unread" in this case
    var type: String = "notification.mark_unread"
    /// The number of channels with unread messages
    var unreadChannels: Int?
    /// The total number of unread messages
    var unreadCount: Int?
    /// The number of unread messages in the channel/thread after first_unread_message_id
    var unreadMessages: Int?
    /// The total number of unread messages in the threads
    var unreadThreadMessages: Int?
    /// The number of unread threads
    var unreadThreads: Int?
    var user: UserResponseCommonFields?

    init(channel: ChannelResponse? = nil, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], firstUnreadMessageId: String? = nil, groupedUnreadChannels: [String: Int]? = nil, lastReadAt: Date? = nil, lastReadMessageId: String? = nil, receivedAt: Date? = nil, team: String? = nil, threadId: String? = nil, totalUnreadCount: Int? = nil, unreadChannels: Int? = nil, unreadCount: Int? = nil, unreadMessages: Int? = nil, unreadThreadMessages: Int? = nil, unreadThreads: Int? = nil, user: UserResponseCommonFields? = nil) {
        self.channel = channel
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.firstUnreadMessageId = firstUnreadMessageId
        self.groupedUnreadChannels = groupedUnreadChannels
        self.lastReadAt = lastReadAt
        self.lastReadMessageId = lastReadMessageId
        self.receivedAt = receivedAt
        self.team = team
        self.threadId = threadId
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.unreadMessages = unreadMessages
        self.unreadThreadMessages = unreadThreadMessages
        self.unreadThreads = unreadThreads
        self.user = user
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
        case firstUnreadMessageId = "first_unread_message_id"
        case groupedUnreadChannels = "grouped_unread_channels"
        case lastReadAt = "last_read_at"
        case lastReadMessageId = "last_read_message_id"
        case receivedAt = "received_at"
        case team
        case threadId = "thread_id"
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case unreadMessages = "unread_messages"
        case unreadThreadMessages = "unread_thread_messages"
        case unreadThreads = "unread_threads"
        case user
    }

    static func == (lhs: NotificationMarkUnreadEventOpenAPI, rhs: NotificationMarkUnreadEventOpenAPI) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.firstUnreadMessageId == rhs.firstUnreadMessageId &&
            lhs.groupedUnreadChannels == rhs.groupedUnreadChannels &&
            lhs.lastReadAt == rhs.lastReadAt &&
            lhs.lastReadMessageId == rhs.lastReadMessageId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.threadId == rhs.threadId &&
            lhs.totalUnreadCount == rhs.totalUnreadCount &&
            lhs.type == rhs.type &&
            lhs.unreadChannels == rhs.unreadChannels &&
            lhs.unreadCount == rhs.unreadCount &&
            lhs.unreadMessages == rhs.unreadMessages &&
            lhs.unreadThreadMessages == rhs.unreadThreadMessages &&
            lhs.unreadThreads == rhs.unreadThreads &&
            lhs.user == rhs.user
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
        hasher.combine(firstUnreadMessageId)
        hasher.combine(groupedUnreadChannels)
        hasher.combine(lastReadAt)
        hasher.combine(lastReadMessageId)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(threadId)
        hasher.combine(totalUnreadCount)
        hasher.combine(type)
        hasher.combine(unreadChannels)
        hasher.combine(unreadCount)
        hasher.combine(unreadMessages)
        hasher.combine(unreadThreadMessages)
        hasher.combine(unreadThreads)
        hasher.combine(user)
    }
}

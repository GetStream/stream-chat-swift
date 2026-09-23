//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationMarkReadEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel which was marked as read
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel which was marked as read
    let channelType: String?
    /// The CID of the channel which was marked as read
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let groupedUnreadChannels: [String: Int]?
    /// The ID of the last read message
    let lastReadMessageId: String?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    let thread: ThreadResponse?
    /// The ID of the thread which was marked as read
    let threadId: String?
    /// The total number of unread messages
    let totalUnreadCount: Int
    /// The type of event: "notification.mark_read" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int
    /// The total number of unread messages
    let unreadCount: Int
    /// The total number of unread messages in the threads
    let unreadThreadMessages: Int?
    /// The number of unread threads
    let unreadThreads: Int?
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        groupedUnreadChannels: [String: Int]? = nil,
        lastReadMessageId: String? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        thread: ThreadResponse? = nil,
        threadId: String? = nil,
        totalUnreadCount: Int,
        type: String = "notification.mark_read",
        unreadChannels: Int,
        unreadCount: Int,
        unreadThreadMessages: Int? = nil,
        unreadThreads: Int? = nil,
        user: UserPayload? = nil
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
        self.lastReadMessageId = lastReadMessageId
        self.receivedAt = receivedAt
        self.team = team
        self.thread = thread
        self.threadId = threadId
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
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
        case groupedUnreadChannels = "grouped_unread_channels"
        case lastReadMessageId = "last_read_message_id"
        case receivedAt = "received_at"
        case team
        case thread
        case threadId = "thread_id"
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case unreadThreadMessages = "unread_thread_messages"
        case unreadThreads = "unread_threads"
        case user
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageNewEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was sent
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The type of the channel where the message was sent
    let channelType: String?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let groupedUnreadChannels: [String: Int]?
    /// Represents any chat message
    let message: MessageResponse
    let messageId: String?
    /// The author of the parent message
    let parentAuthor: String?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    /// The participants of the thread
    let threadParticipants: [UserPayload]?
    let totalUnreadCount: Int?
    /// The type of event: "message.new" in this case
    let type: String
    let unreadChannels: Int?
    /// The number of unread messages
    let unreadCount: Int?
    let user: UserPayload?
    /// The number of watchers
    let watcherCount: Int?

    init(
        channel: ChannelDetailPayload? = nil,
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        groupedUnreadChannels: [String: Int]? = nil,
        message: MessageResponse,
        messageId: String? = nil,
        parentAuthor: String? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        threadParticipants: [UserPayload]? = nil,
        totalUnreadCount: Int? = nil,
        type: String = "message.new",
        unreadChannels: Int? = nil,
        unreadCount: Int? = nil,
        user: UserPayload? = nil,
        watcherCount: Int? = nil
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
        self.message = message
        self.messageId = messageId
        self.parentAuthor = parentAuthor
        self.receivedAt = receivedAt
        self.team = team
        self.threadParticipants = threadParticipants
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.user = user
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
        case user
        case watcherCount = "watcher_count"
    }
}

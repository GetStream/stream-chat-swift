//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationThreadMessageNewEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was sent
    let channelId: String?
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel where the message was sent
    let channelType: String?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// Represents any chat message
    let message: MessageResponse
    let messageId: String
    let parentAuthor: String?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    /// The ID of the thread
    let threadId: String
    /// The participants of the thread
    let threadParticipants: [UserPayload]?
    /// The type of event: "notification.message_new" in this case
    let type: String
    let unreadThreadMessages: Int?
    let unreadThreads: Int?
    /// The number of watchers
    let watcherCount: Int

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
        message: MessageResponse,
        messageId: String,
        parentAuthor: String? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        threadId: String,
        threadParticipants: [UserPayload]? = nil,
        type: String = "notification.thread_message_new",
        unreadThreadMessages: Int? = nil,
        unreadThreads: Int? = nil,
        watcherCount: Int
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
        self.message = message
        self.messageId = messageId
        self.parentAuthor = parentAuthor
        self.receivedAt = receivedAt
        self.team = team
        self.threadId = threadId
        self.threadParticipants = threadParticipants
        self.type = type
        self.unreadThreadMessages = unreadThreadMessages
        self.unreadThreads = unreadThreads
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
        case message
        case messageId = "message_id"
        case parentAuthor = "parent_author"
        case receivedAt = "received_at"
        case team
        case threadId = "thread_id"
        case threadParticipants = "thread_participants"
        case type
        case unreadThreadMessages = "unread_thread_messages"
        case unreadThreads = "unread_threads"
        case watcherCount = "watcher_count"
    }
}

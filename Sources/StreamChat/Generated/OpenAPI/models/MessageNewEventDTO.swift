//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageNewEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let groupedUnreadChannels: [String: Int]?
    /// Represents any chat message
    let message: MessageResponse
    let totalUnreadCount: Int?
    /// The type of event: "message.new" in this case
    let type: String
    let unreadChannels: Int?
    let user: UserPayload?
    /// The number of watchers
    let watcherCount: Int?

    init(
        channel: ChannelDetailPayload? = nil,
        channelMessageCount: Int? = nil,
        cid: ChannelId,
        createdAt: Date,
        groupedUnreadChannels: [String: Int]? = nil,
        message: MessageResponse,
        totalUnreadCount: Int? = nil,
        type: String = "message.new",
        unreadChannels: Int? = nil,
        user: UserPayload? = nil,
        watcherCount: Int? = nil
    ) {
        self.channel = channel
        self.channelMessageCount = channelMessageCount
        self.cid = cid
        self.createdAt = createdAt
        self.groupedUnreadChannels = groupedUnreadChannels
        self.message = message
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.user = user
        self.watcherCount = watcherCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelMessageCount = "channel_message_count"
        case cid
        case createdAt = "created_at"
        case groupedUnreadChannels = "grouped_unread_channels"
        case message
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case user
        case watcherCount = "watcher_count"
    }
}

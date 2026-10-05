//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationNewMessageEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelMessageCount: Int?
    /// Date/time of creation
    let createdAt: Date
    let groupedUnreadChannels: [String: Int]?
    /// Represents any chat message
    let message: MessageResponse
    let totalUnreadCount: Int?
    /// The type of event: "notification.message_new" in this case
    let type: String
    let unreadChannels: Int?

    init(
        channel: ChannelDetailPayload,
        channelMessageCount: Int? = nil,
        createdAt: Date,
        groupedUnreadChannels: [String: Int]? = nil,
        message: MessageResponse,
        totalUnreadCount: Int? = nil,
        type: String = "notification.message_new",
        unreadChannels: Int? = nil
    ) {
        self.channel = channel
        self.channelMessageCount = channelMessageCount
        self.createdAt = createdAt
        self.groupedUnreadChannels = groupedUnreadChannels
        self.message = message
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelMessageCount = "channel_message_count"
        case createdAt = "created_at"
        case groupedUnreadChannels = "grouped_unread_channels"
        case message
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
    }
}

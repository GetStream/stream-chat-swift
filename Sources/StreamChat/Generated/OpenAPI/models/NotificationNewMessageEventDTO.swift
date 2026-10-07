//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a new message was sent to a channel.
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.channelMessageCount = try container.decodeIfPresent(
            Int.self,
            forKey: .channelMessageCount
        )
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.groupedUnreadChannels = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .groupedUnreadChannels
        )
        self.message = try container.decode(MessageResponse.self, forKey: .message)
        self.totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a message was successfully sent or when a message became visible after command execution.
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.channelMessageCount = try container.decodeIfPresent(
            Int.self,
            forKey: .channelMessageCount
        )
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.groupedUnreadChannels = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .groupedUnreadChannels
        )
        self.message = try container.decode(MessageResponse.self, forKey: .message)
        self.totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        self.watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
    }
}

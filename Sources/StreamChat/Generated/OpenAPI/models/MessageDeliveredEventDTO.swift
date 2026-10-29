//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a message is marked as delivered.
final class MessageDeliveredEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The CID of the channel where the message was read
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The time when the message was delivered
    let lastDeliveredAt: Date?
    /// The ID of the last delivered message
    let lastDeliveredMessageId: String?
    /// The type of event: "message.delivered" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId,
        createdAt: Date,
        lastDeliveredAt: Date? = nil,
        lastDeliveredMessageId: String? = nil,
        type: String = "message.delivered",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.lastDeliveredAt = lastDeliveredAt
        self.lastDeliveredMessageId = lastDeliveredMessageId
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastDeliveredAt = try container.decodeIfPresent(Date.self, forKey: .lastDeliveredAt)
        self.lastDeliveredMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .lastDeliveredMessageId
        )
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

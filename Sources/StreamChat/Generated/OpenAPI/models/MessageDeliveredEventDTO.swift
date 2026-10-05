//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case cid
        case createdAt = "created_at"
        case lastDeliveredAt = "last_delivered_at"
        case lastDeliveredMessageId = "last_delivered_message_id"
        case type
        case user
    }
}

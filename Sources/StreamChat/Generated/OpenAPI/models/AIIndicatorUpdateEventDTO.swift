//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when the AI indicator is updated.
final class AIIndicatorUpdateEventDTO: Sendable, Event, Decodable {
    /// Optional message from the AI
    let aiMessage: String?
    /// The state of the AI indicator
    let aiState: String
    /// The CID of the channel
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    /// The ID of the message
    let messageId: String
    /// The type of event: "ai_indicator.update" in this case
    let type: String

    init(
        aiMessage: String? = nil,
        aiState: String,
        cid: ChannelId? = nil,
        createdAt: Date,
        messageId: String,
        type: String = "ai_indicator.update"
    ) {
        self.aiMessage = aiMessage
        self.aiState = aiState
        self.cid = cid
        self.createdAt = createdAt
        self.messageId = messageId
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.aiMessage = try container.decodeIfPresent(String.self, forKey: .aiMessage)
        self.aiState = try container.decode(String.self, forKey: .aiState)
        self.cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

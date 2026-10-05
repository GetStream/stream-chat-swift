//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case aiMessage = "ai_message"
        case aiState = "ai_state"
        case cid
        case createdAt = "created_at"
        case messageId = "message_id"
        case type
    }
}

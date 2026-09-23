//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIIndicatorUpdateEventDTO: Sendable, Event, Decodable {
    /// Optional message from the AI
    let aiMessage: String?
    /// The state of the AI indicator
    let aiState: String
    /// The ID of the channel
    let channelId: String?
    /// The type of the channel
    let channelType: String?
    /// The CID of the channel
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// The ID of the message
    let messageId: String
    let receivedAt: Date?
    /// The type of event: "ai_indicator.update" in this case
    let type: String

    init(
        aiMessage: String? = nil,
        aiState: String,
        channelId: String? = nil,
        channelType: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        messageId: String,
        receivedAt: Date? = nil,
        type: String = "ai_indicator.update"
    ) {
        self.aiMessage = aiMessage
        self.aiState = aiState
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.receivedAt = receivedAt
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case aiMessage = "ai_message"
        case aiState = "ai_state"
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case messageId = "message_id"
        case receivedAt = "received_at"
        case type
    }
}

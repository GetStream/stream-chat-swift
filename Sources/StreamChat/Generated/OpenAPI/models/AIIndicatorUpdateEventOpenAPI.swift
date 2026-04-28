//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIIndicatorUpdateEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Optional message from the AI
    var aiMessage: String?
    /// The state of the AI indicator
    var aiState: String
    /// The ID of the channel
    var channelId: String?
    /// The type of the channel
    var channelType: String?
    /// The CID of the channel
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The ID of the message
    var messageId: String
    var receivedAt: Date?
    /// The type of event: "ai_indicator.update" in this case
    var type: String = "ai_indicator.update"

    init(aiMessage: String? = nil, aiState: String, channelId: String? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], messageId: String, receivedAt: Date? = nil) {
        self.aiMessage = aiMessage
        self.aiState = aiState
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.receivedAt = receivedAt
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

    static func == (lhs: AIIndicatorUpdateEventOpenAPI, rhs: AIIndicatorUpdateEventOpenAPI) -> Bool {
        lhs.aiMessage == rhs.aiMessage &&
            lhs.aiState == rhs.aiState &&
            lhs.channelId == rhs.channelId &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.messageId == rhs.messageId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(aiMessage)
        hasher.combine(aiState)
        hasher.combine(channelId)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(messageId)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}

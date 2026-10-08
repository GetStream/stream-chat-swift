//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReminderPayload: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let channelCid: String
    let createdAt: Date
    /// Represents any chat message
    let message: MessageResponse?
    let messageId: String
    let remindAt: Date?
    let updatedAt: Date
    let userId: String

    init(
        channel: ChannelDetailPayload? = nil,
        channelCid: String,
        createdAt: Date,
        message: MessageResponse? = nil,
        messageId: String,
        remindAt: Date? = nil,
        updatedAt: Date,
        userId: String
    ) {
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.message = message
        self.messageId = messageId
        self.remindAt = remindAt
        self.updatedAt = updatedAt
        self.userId = userId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.channelCid = try container.decode(String.self, forKey: .channelCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.message = try container.decodeIfPresent(MessageResponse.self, forKey: .message)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.remindAt = try container.decodeIfPresent(Date.self, forKey: .remindAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.userId = try container.decode(String.self, forKey: .userId)
    }
}

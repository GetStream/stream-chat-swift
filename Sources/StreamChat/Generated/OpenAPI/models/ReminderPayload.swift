//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReminderPayload: Sendable, Codable, JSONEncodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let channelCid: String
    let createdAt: Date
    /// Represents any chat message
    let message: MessagePayload?
    let messageId: String
    let remindAt: Date?
    let updatedAt: Date
    /// User response object
    let user: UserPayload?
    let userId: String

    init(
        channel: ChannelDetailPayload? = nil,
        channelCid: String,
        createdAt: Date,
        message: MessagePayload? = nil,
        messageId: String,
        remindAt: Date? = nil,
        updatedAt: Date,
        user: UserPayload? = nil,
        userId: String
    ) {
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.message = message
        self.messageId = messageId
        self.remindAt = remindAt
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case message
        case messageId = "message_id"
        case remindAt = "remind_at"
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}

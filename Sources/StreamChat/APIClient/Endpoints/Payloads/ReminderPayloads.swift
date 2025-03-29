//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing a reminder JSON payload.
class ReminderPayload: Decodable {
    let channelCid: ChannelId
    let channel: ChannelDetailPayload?
    let messageId: MessageId
    let message: MessagePayload?
    let remindAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        channelCid: ChannelId,
        messageId: MessageId,
        message: MessagePayload? = nil,
        channel: ChannelDetailPayload? = nil,
        remindAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.channelCid = channelCid
        self.messageId = messageId
        self.message = message
        self.channel = channel
        self.remindAt = remindAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case channelCid = "channel_cid"
        case messageId = "message_id"
        case message
        case channel
        case remindAt = "remind_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// A request body for creating or updating a reminder
class ReminderRequestBody: Encodable {
    let remindAt: Date?
    
    init(
        remindAt: Date?
    ) {
        self.remindAt = remindAt
    }
    
    enum CodingKeys: String, CodingKey {
        case remindAt = "remind_at"
    }
}

/// A response containing a list of reminders
class RemindersQueryPayload: Decodable {
    let reminders: [ReminderPayload]
    let next: String?
}

/// A response containing a single reminder
class ReminderResponsePayload: Decodable {
    let reminder: ReminderPayload
}

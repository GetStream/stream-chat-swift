//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReminderUpdatedEventDTO: Sendable, Event, Decodable {
    /// The CID of the Channel for which the reminder was created
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// The ID of the message for which the reminder was created
    let messageId: String
    /// The ID of the parent message, if the reminder is for a thread message
    let parentId: String?
    let receivedAt: Date?
    let reminder: ReminderPayload
    /// The type of event: "reminder.updated" in this case
    let type: String
    /// The ID of the user for whom the reminder was created
    let userId: String

    init(
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        messageId: String,
        parentId: String? = nil,
        receivedAt: Date? = nil,
        reminder: ReminderPayload,
        type: String = "reminder.updated",
        userId: String
    ) {
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.parentId = parentId
        self.receivedAt = receivedAt
        self.reminder = reminder
        self.type = type
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case custom
        case messageId = "message_id"
        case parentId = "parent_id"
        case receivedAt = "received_at"
        case reminder
        case type
        case userId = "user_id"
    }
}

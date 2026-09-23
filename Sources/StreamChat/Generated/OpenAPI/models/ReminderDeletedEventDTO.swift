//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReminderDeletedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// The ID of the message for which the reminder was created
    let messageId: String
    let reminder: ReminderPayload
    /// The type of event: "reminder.deleted" in this case
    let type: String

    init(
        createdAt: Date,
        messageId: String,
        reminder: ReminderPayload,
        type: String = "reminder.deleted"
    ) {
        self.createdAt = createdAt
        self.messageId = messageId
        self.reminder = reminder
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case messageId = "message_id"
        case reminder
        case type
    }
}

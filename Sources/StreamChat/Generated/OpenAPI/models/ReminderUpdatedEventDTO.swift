//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a reminder is updated.
final class ReminderUpdatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// The ID of the message for which the reminder was created
    let messageId: String
    let reminder: ReminderPayload
    /// The type of event: "reminder.updated" in this case
    let type: String

    init(
        createdAt: Date,
        messageId: String,
        reminder: ReminderPayload,
        type: String = "reminder.updated"
    ) {
        self.createdAt = createdAt
        self.messageId = messageId
        self.reminder = reminder
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.reminder = try container.decode(ReminderPayload.self, forKey: .reminder)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

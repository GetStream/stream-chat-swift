//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A request body for creating or updating a reminder
final class ReminderRequestBody: Encodable, Sendable {
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
final class RemindersQueryPayload: Decodable, Sendable {
    let reminders: [ReminderPayload]
    let next: String?

    init(reminders: [ReminderPayload], next: String?) {
        self.reminders = reminders
        self.next = next
    }
}

/// A response containing a single reminder
final class ReminderResponsePayload: Decodable, Sendable {
    let reminder: ReminderPayload

    init(reminder: ReminderPayload) {
        self.reminder = reminder
    }
}

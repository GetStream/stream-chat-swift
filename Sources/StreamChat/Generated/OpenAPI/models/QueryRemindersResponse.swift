//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryRemindersResponse: Sendable, Decodable {
    let next: String?
    let prev: String?
    /// MessageReminders data returned by the query
    let reminders: [ReminderPayload]

    init(next: String? = nil, prev: String? = nil, reminders: [ReminderPayload]) {
        self.next = next
        self.prev = prev
        self.reminders = reminders
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
        self.reminders = try container.decode([ReminderPayload].self, forKey: .reminders)
    }
}

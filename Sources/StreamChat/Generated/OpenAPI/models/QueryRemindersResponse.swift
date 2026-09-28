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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        case prev
        case reminders
    }
}

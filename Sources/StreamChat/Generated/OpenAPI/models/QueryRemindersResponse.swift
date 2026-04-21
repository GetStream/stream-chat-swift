//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryRemindersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var next: String?
    var prev: String?
    /// MessageReminders data returned by the query
    var reminders: [ReminderResponseData]

    init(duration: String, next: String? = nil, prev: String? = nil, reminders: [ReminderResponseData]) {
        self.duration = duration
        self.next = next
        self.prev = prev
        self.reminders = reminders
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case prev
        case reminders
    }

    static func == (lhs: QueryRemindersResponse, rhs: QueryRemindersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.reminders == rhs.reminders
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(reminders)
    }
}

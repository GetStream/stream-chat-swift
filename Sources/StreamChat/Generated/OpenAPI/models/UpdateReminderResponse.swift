//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateReminderResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var reminder: ReminderResponseData

    init(duration: String, reminder: ReminderResponseData) {
        self.duration = duration
        self.reminder = reminder
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case reminder
    }

    static func == (lhs: UpdateReminderResponse, rhs: UpdateReminderResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.reminder == rhs.reminder
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(reminder)
    }
}

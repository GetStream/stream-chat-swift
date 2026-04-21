//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateReminderRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var remindAt: Date?

    init(remindAt: Date? = nil) {
        self.remindAt = remindAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case remindAt = "remind_at"
    }

    static func == (lhs: CreateReminderRequest, rhs: CreateReminderRequest) -> Bool {
        lhs.remindAt == rhs.remindAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(remindAt)
    }
}

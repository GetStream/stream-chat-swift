//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateReminderRequest: Sendable, Encodable, JSONEncodable {
    let remindAt: Date?

    init(remindAt: Date? = nil) {
        self.remindAt = remindAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case remindAt = "remind_at"
    }
}

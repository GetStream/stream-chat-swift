//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class UpdateReminderResponse: Sendable, Decodable {
    let reminder: ReminderPayload

    init(reminder: ReminderPayload) {
        self.reminder = reminder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.reminder = try container.decode(ReminderPayload.self, forKey: .reminder)
    }
}

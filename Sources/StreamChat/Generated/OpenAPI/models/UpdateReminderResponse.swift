//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateReminderResponse: Sendable, Decodable {
    let reminder: ReminderPayload

    init(reminder: ReminderPayload) {
        self.reminder = reminder
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case reminder
    }
}

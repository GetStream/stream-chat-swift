//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateReminderResponse: Sendable, Decodable {
    let reminder: ReminderPayload

    init(reminder: ReminderPayload) {
        self.reminder = reminder
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case reminder
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateReminderRequest: Sendable, Encodable, JSONEncodable {
    let remindAt: Date?

    init(remindAt: Date? = nil) {
        self.remindAt = remindAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(remindAt, forKey: .remindAt)
    }
}

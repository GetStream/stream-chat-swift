//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateScheduledMessageRequest: Sendable, Encodable, JSONEncodable {
    /// Message data for creating or updating a message
    let message: MessageRequest?
    /// New send time (UTC). Must be at least 1 minute and at most the app's maximum lead time from now
    let scheduledAt: Date?

    init(message: MessageRequest? = nil, scheduledAt: Date? = nil) {
        self.message = message
        self.scheduledAt = scheduledAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(scheduledAt, forKey: .scheduledAt)
    }
}

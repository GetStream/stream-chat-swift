//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a scheduled message fails to send. scheduled_message.failure_reason says why.
final class ScheduledMessageFailedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// A message scheduled to be sent later
    let scheduledMessage: ScheduledMessageResponse?
    /// The type of event: "scheduled_message.failed" in this case
    let type: String

    init(
        createdAt: Date,
        scheduledMessage: ScheduledMessageResponse? = nil,
        type: String = "scheduled_message.failed"
    ) {
        self.createdAt = createdAt
        self.scheduledMessage = scheduledMessage
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.scheduledMessage = try container.decodeIfPresent(
            ScheduledMessageResponse.self,
            forKey: .scheduledMessage
        )
        self.type = try container.decode(String.self, forKey: .type)
    }
}

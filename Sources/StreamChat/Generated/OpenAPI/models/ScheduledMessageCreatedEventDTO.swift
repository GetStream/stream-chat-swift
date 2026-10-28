//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a message is scheduled to be sent later.
final class ScheduledMessageCreatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// A message scheduled to be sent later
    let scheduledMessage: ScheduledMessageResponse?
    /// The type of event: "scheduled_message.created" in this case
    let type: String

    init(
        createdAt: Date,
        scheduledMessage: ScheduledMessageResponse? = nil,
        type: String = "scheduled_message.created"
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

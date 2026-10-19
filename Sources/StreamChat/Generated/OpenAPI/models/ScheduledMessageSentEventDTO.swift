//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a scheduled message is sent.
final class ScheduledMessageSentEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// The ID of the message that was sent
    let messageId: String
    /// A message scheduled to be sent later
    let scheduledMessage: ScheduledMessageResponse?
    /// The type of event: "scheduled_message.sent" in this case
    let type: String

    init(
        createdAt: Date,
        messageId: String,
        scheduledMessage: ScheduledMessageResponse? = nil,
        type: String = "scheduled_message.sent"
    ) {
        self.createdAt = createdAt
        self.messageId = messageId
        self.scheduledMessage = scheduledMessage
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.scheduledMessage = try container.decodeIfPresent(
            ScheduledMessageResponse.self,
            forKey: .scheduledMessage
        )
        self.type = try container.decode(String.self, forKey: .type)
    }
}

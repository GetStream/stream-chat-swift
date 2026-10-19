//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendMessageRequest: Sendable, Encodable, JSONEncodable {
    /// Message data for creating or updating a message
    let message: MessageRequest
    /// When set, the message is not sent now: it is stored and sent at this time (UTC). The response then carries scheduled_message. Must be at least 1 minute and at most the app's maximum lead time (120 days by default) from now. Slash commands cannot be scheduled
    let scheduledAt: Date?
    let skipEnrichUrl: Bool?
    let skipPush: Bool?

    init(
        message: MessageRequest,
        scheduledAt: Date? = nil,
        skipEnrichUrl: Bool? = nil,
        skipPush: Bool? = nil
    ) {
        self.message = message
        self.scheduledAt = scheduledAt
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(scheduledAt, forKey: .scheduledAt)
        try container.encodeIfPresent(skipEnrichUrl, forKey: .skipEnrichUrl)
        try container.encodeIfPresent(skipPush, forKey: .skipPush)
    }
}

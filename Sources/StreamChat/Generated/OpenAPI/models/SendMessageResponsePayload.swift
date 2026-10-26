//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendMessageResponsePayload: Sendable, Decodable {
    /// Represents any chat message
    let message: MessageResponse
    /// A message scheduled to be sent later
    let scheduledMessage: ScheduledMessageResponse?

    init(message: MessageResponse, scheduledMessage: ScheduledMessageResponse? = nil) {
        self.message = message
        self.scheduledMessage = scheduledMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.message = try container.decode(MessageResponse.self, forKey: .message)
        self.scheduledMessage = try container.decodeIfPresent(
            ScheduledMessageResponse.self,
            forKey: .scheduledMessage
        )
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendScheduledMessageNowResponse: Sendable, Decodable {
    /// A message scheduled to be sent later
    let scheduledMessage: ScheduledMessageResponse

    init(scheduledMessage: ScheduledMessageResponse) {
        self.scheduledMessage = scheduledMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.scheduledMessage = try container.decode(
            ScheduledMessageResponse.self,
            forKey: .scheduledMessage
        )
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryScheduledMessagesResponse: Sendable, Decodable {
    /// Cursor for the next page; empty on the last page
    let next: String?
    /// Pending messages first, then failed ones, each by scheduled_at
    let scheduledMessages: [ScheduledMessageResponse]

    init(next: String? = nil, scheduledMessages: [ScheduledMessageResponse]) {
        self.next = next
        self.scheduledMessages = scheduledMessages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.scheduledMessages = try container.decode(
            [ScheduledMessageResponse].self,
            forKey: .scheduledMessages
        )
    }
}

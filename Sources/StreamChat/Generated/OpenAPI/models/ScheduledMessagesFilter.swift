//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Filter for querying scheduled messages
final class ScheduledMessagesFilter: Sendable, Encodable, JSONEncodable {
    /// Only scheduled messages of this channel
    let cid: String?
    /// Only these statuses, as reported in each scheduled message's status. One or more of: scheduled, sending, failed
    let status: [ScheduledMessageQueryStatus]?

    init(cid: String? = nil, status: [ScheduledMessageQueryStatus]? = nil) {
        self.cid = cid
        self.status = status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encodeIfPresent(status, forKey: .status)
    }
}

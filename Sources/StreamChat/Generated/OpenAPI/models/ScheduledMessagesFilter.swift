//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Filter for querying scheduled messages
final class ScheduledMessagesFilter: Sendable, Encodable, JSONEncodable {
    /// Only scheduled messages of this channel
    let cid: String?
    /// Only these statuses. One or more of: scheduled, sending, failed
    let status: [String]?

    init(cid: String? = nil, status: [String]? = nil) {
        self.cid = cid
        self.status = status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encodeIfPresent(status, forKey: .status)
    }
}

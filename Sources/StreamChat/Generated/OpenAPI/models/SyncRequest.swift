//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sync request
final class SyncRequest: Sendable, Encodable, JSONEncodable {
    /// List of channel CIDs to sync
    let channelCids: [String]
    /// Date from which synchronization should happen
    let lastSyncAt: Date

    init(channelCids: [String], lastSyncAt: Date) {
        self.channelCids = channelCids
        self.lastSyncAt = lastSyncAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(channelCids, forKey: .channelCids)
        try container.encode(lastSyncAt, forKey: .lastSyncAt)
    }
}

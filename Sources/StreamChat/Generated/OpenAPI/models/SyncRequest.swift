//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SyncRequest: Sendable, Encodable, JSONEncodable {
    /// List of channel CIDs to sync
    let channelCids: [String]
    /// Date from which synchronization should happen
    let lastSyncAt: Date

    init(channelCids: [String], lastSyncAt: Date) {
        self.channelCids = channelCids
        self.lastSyncAt = lastSyncAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        case lastSyncAt = "last_sync_at"
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SyncRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of channel CIDs to sync
    var channelCids: [String]
    /// Date from which synchronization should happen
    var lastSyncAt: Date

    init(channelCids: [String], lastSyncAt: Date) {
        self.channelCids = channelCids
        self.lastSyncAt = lastSyncAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        case lastSyncAt = "last_sync_at"
    }

    static func == (lhs: SyncRequest, rhs: SyncRequest) -> Bool {
        lhs.channelCids == rhs.channelCids &&
            lhs.lastSyncAt == rhs.lastSyncAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCids)
        hasher.combine(lastSyncAt)
    }
}

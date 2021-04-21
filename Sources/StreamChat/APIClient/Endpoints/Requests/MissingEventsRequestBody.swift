//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `/sync` endpoint
struct MissingEventsRequestBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case lastSyncedAt = "last_sync_at"
        case cids = "channel_cids"
    }
    
    let lastSyncedAt: Date
    let cids: [ChannelId]
}

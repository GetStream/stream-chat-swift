//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SyncRequest: Codable, Hashable {
    public var lastSyncAt: Date
    public var channelCids: [String]
    public var connectionId: String? = nil
    public var watch: Bool? = nil
    public var withInaccessibleCids: Bool? = nil

    public init(lastSyncAt: Date, channelCids: [String], connectionId: String? = nil, watch: Bool? = nil, withInaccessibleCids: Bool? = nil) {
        self.lastSyncAt = lastSyncAt
        self.channelCids = channelCids
        self.connectionId = connectionId
        self.watch = watch
        self.withInaccessibleCids = withInaccessibleCids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastSyncAt = "last_sync_at"
        case channelCids = "channel_cids"
        case connectionId = "connection_id"
        case watch
        case withInaccessibleCids = "with_inaccessible_cids"
    }
}

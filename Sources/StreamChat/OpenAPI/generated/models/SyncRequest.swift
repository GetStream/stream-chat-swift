//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SyncRequest: Codable, Hashable {
    public var lastSyncAt: Date
    public var connectionId: String? = nil
    public var watch: Bool? = nil
    public var withInaccessibleCids: Bool? = nil
    public var channelCids: [String]? = nil

    public init(lastSyncAt: Date, connectionId: String? = nil, watch: Bool? = nil, withInaccessibleCids: Bool? = nil, channelCids: [String]? = nil) {
        self.lastSyncAt = lastSyncAt
        self.connectionId = connectionId
        self.watch = watch
        self.withInaccessibleCids = withInaccessibleCids
        self.channelCids = channelCids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastSyncAt = "last_sync_at"
        case connectionId = "connection_id"
        case watch
        case withInaccessibleCids = "with_inaccessible_cids"
        case channelCids = "channel_cids"
    }
}

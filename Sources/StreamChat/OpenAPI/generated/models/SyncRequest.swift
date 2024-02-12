//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SyncRequest: Codable, Hashable {
    public var lastSyncAt: Date
    
    public var connectionId: String? = nil
    
    public var userId: String? = nil
    
    public var watch: Bool? = nil
    
    public var withInaccessibleCids: Bool? = nil
    
    public var channelCids: [String]? = nil
    
    public var user: UserObjectRequest? = nil
    
    public init(lastSyncAt: Date, connectionId: String? = nil, userId: String? = nil, watch: Bool? = nil, withInaccessibleCids: Bool? = nil, channelCids: [String]? = nil, user: UserObjectRequest? = nil) {
        self.lastSyncAt = lastSyncAt
        
        self.connectionId = connectionId
        
        self.userId = userId
        
        self.watch = watch
        
        self.withInaccessibleCids = withInaccessibleCids
        
        self.channelCids = channelCids
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastSyncAt = "last_sync_at"
        
        case connectionId = "connection_id"
        
        case userId = "user_id"
        
        case watch
        
        case withInaccessibleCids = "with_inaccessible_cids"
        
        case channelCids = "channel_cids"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastSyncAt, forKey: .lastSyncAt)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(withInaccessibleCids, forKey: .withInaccessibleCids)
        
        try container.encode(channelCids, forKey: .channelCids)
        
        try container.encode(user, forKey: .user)
    }
}

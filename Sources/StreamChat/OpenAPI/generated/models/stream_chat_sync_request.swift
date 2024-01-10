//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSyncRequest: Codable, Hashable {
    public var withInaccessibleCids: Bool?
    
    public var channelCids: [String]?
    
    public var connectionId: String?
    
    public var lastSyncAt: String
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public var watch: Bool?
    
    public init(withInaccessibleCids: Bool?, channelCids: [String]?, connectionId: String?, lastSyncAt: String, user: StreamChatUserObjectRequest?, userId: String?, watch: Bool?) {
        self.withInaccessibleCids = withInaccessibleCids
        
        self.channelCids = channelCids
        
        self.connectionId = connectionId
        
        self.lastSyncAt = lastSyncAt
        
        self.user = user
        
        self.userId = userId
        
        self.watch = watch
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case withInaccessibleCids = "with_inaccessible_cids"
        
        case channelCids = "channel_cids"
        
        case connectionId = "connection_id"
        
        case lastSyncAt = "last_sync_at"
        
        case user
        
        case userId = "user_id"
        
        case watch
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(withInaccessibleCids, forKey: .withInaccessibleCids)
        
        try container.encode(channelCids, forKey: .channelCids)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(lastSyncAt, forKey: .lastSyncAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(watch, forKey: .watch)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserWatchingStopEvent: Codable, Hashable, Event {
    public var user: StreamChatUserObject?
    
    public var watcherCount: Int
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var type: String
    
    public init(user: StreamChatUserObject?, watcherCount: Int, channelId: String, channelType: String, cid: String, createdAt: Date, type: String) {
        self.user = user
        
        self.watcherCount = watcherCount
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case watcherCount = "watcher_count"
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
    }
}

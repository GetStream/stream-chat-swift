//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserWatchingStartEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var type: String
    
    public var watcherCount: Int
    
    public var team: String? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, watcherCount: Int, team: String? = nil, user: StreamChatUserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.watcherCount = watcherCount
        
        self.team = team
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case type
        
        case watcherCount = "watcher_count"
        
        case team
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
    }
}

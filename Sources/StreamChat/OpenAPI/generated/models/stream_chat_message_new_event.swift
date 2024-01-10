//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageNewEvent: Codable, Hashable {
    public var channelId: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var watcherCount: Int
    
    public var channelType: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public init(channelId: String, cid: String, createdAt: String, threadParticipants: [StreamChatUserObject]?, type: String, watcherCount: Int, channelType: String, message: StreamChatMessage?, team: String?, user: StreamChatUserObject?) {
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.watcherCount = watcherCount
        
        self.channelType = channelType
        
        self.message = message
        
        self.team = team
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case watcherCount = "watcher_count"
        
        case channelType = "channel_type"
        
        case message
        
        case team
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
    }
}

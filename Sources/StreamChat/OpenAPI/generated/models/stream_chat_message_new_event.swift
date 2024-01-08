//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageNewEvent: Codable, Hashable {
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var watcherCount: Int
    
    public var channelId: String
    
    public var channelType: String
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(cid: String, createdAt: String, message: StreamChatMessage?, watcherCount: Int, channelId: String, channelType: String, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.watcherCount = watcherCount
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case watcherCount = "watcher_count"
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

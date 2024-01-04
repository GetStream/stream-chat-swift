//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageNewEvent: Codable, Hashable {
    public var channelType: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var createdAt: String
    
    public var type: String
    
    public var watcherCount: Int
    
    public var cid: String
    
    public init(channelType: String, message: StreamChatMessage?, team: String?, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?, channelId: String, createdAt: String, type: String, watcherCount: Int, cid: String) {
        self.channelType = channelType
        
        self.message = message
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.user = user
        
        self.channelId = channelId
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.watcherCount = watcherCount
        
        self.cid = cid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case message
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case user
        
        case channelId = "channel_id"
        
        case createdAt = "created_at"
        
        case type
        
        case watcherCount = "watcher_count"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(cid, forKey: .cid)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageNewEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var cid: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var watcherCount: Int
    
    public var channelType: String
    
    public var createdAt: Date
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public init(channelId: String, cid: String, message: StreamChatMessage?, team: String?, user: StreamChatUserObject?, watcherCount: Int, channelType: String, createdAt: Date, threadParticipants: [StreamChatUserObject]?, type: String) {
        self.channelId = channelId
        
        self.cid = cid
        
        self.message = message
        
        self.team = team
        
        self.user = user
        
        self.watcherCount = watcherCount
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.threadParticipants = threadParticipants
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case cid
        
        case message
        
        case team
        
        case user
        
        case watcherCount = "watcher_count"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case threadParticipants = "thread_participants"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
    }
}

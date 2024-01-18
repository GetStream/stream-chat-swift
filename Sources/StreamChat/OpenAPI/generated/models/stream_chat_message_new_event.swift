//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageNewEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var message: StreamChatMessage?
    
    public var user: StreamChatUserObject?
    
    public var type: String
    
    public var watcherCount: Int
    
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: Date
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public init(cid: String, message: StreamChatMessage?, user: StreamChatUserObject?, type: String, watcherCount: Int, channelId: String, channelType: String, createdAt: Date, team: String?, threadParticipants: [StreamChatUserObject]?) {
        self.cid = cid
        
        self.message = message
        
        self.user = user
        
        self.type = type
        
        self.watcherCount = watcherCount
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.team = team
        
        self.threadParticipants = threadParticipants
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case message
        
        case user
        
        case type
        
        case watcherCount = "watcher_count"
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case team
        
        case threadParticipants = "thread_participants"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
    }
}

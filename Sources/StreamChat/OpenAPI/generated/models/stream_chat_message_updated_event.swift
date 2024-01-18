//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageUpdatedEvent: Codable, Hashable, Event {
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var channelType: String
    
    public init(threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?, channelId: String, cid: String, createdAt: Date, message: StreamChatMessage?, team: String?, channelType: String) {
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelType, forKey: .channelType)
    }
}

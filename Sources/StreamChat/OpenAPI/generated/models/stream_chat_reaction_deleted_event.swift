//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionDeletedEvent: Codable, Hashable, Event {
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var channelId: String
    
    public var cid: String
    
    public var reaction: StreamChatReaction?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var createdAt: String
    
    public init(message: StreamChatMessage?, team: String?, channelId: String, cid: String, reaction: StreamChatReaction?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?, channelType: String, createdAt: String) {
        self.message = message
        
        self.team = team
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.reaction = reaction
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
        
        self.channelType = channelType
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case team
        
        case channelId = "channel_id"
        
        case cid
        
        case reaction
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionNewEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var type: String
    
    public var cid: String
    
    public var reaction: StreamChatReaction?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public init(channelId: String, channelType: String, createdAt: String, message: StreamChatMessage?, type: String, cid: String, reaction: StreamChatReaction?, team: String?, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.type = type
        
        self.cid = cid
        
        self.reaction = reaction
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case message
        
        case type
        
        case cid
        
        case reaction
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
    }
}

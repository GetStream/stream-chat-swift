//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionUpdatedEvent: Codable, Hashable, Event {
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var reaction: StreamChatReaction
    
    public var team: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var message: StreamChatMessage
    
    public init(channelType: String, cid: String, createdAt: String, reaction: StreamChatReaction, team: String?, type: String, user: StreamChatUserObject?, channelId: String, message: StreamChatMessage) {
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.reaction = reaction
        
        self.team = team
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case reaction
        
        case team
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(message, forKey: .message)
    }
}

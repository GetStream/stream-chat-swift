//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionUpdatedEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var createdAt: Date
    
    public var message: StreamChatMessage
    
    public var reaction: StreamChatReaction
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var type: String
    
    public init(cid: String, createdAt: Date, message: StreamChatMessage, reaction: StreamChatReaction, team: String?, user: StreamChatUserObject?, channelId: String, channelType: String, type: String) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.reaction = reaction
        
        self.team = team
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case reaction
        
        case team
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(type, forKey: .type)
    }
}

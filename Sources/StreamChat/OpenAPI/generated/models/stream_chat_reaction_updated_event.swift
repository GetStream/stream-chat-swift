//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionUpdatedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var message: StreamChatMessage
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var team: String?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var reaction: StreamChatReaction
    
    public init(createdAt: Date, message: StreamChatMessage, type: String, user: StreamChatUserObject?, team: String?, channelId: String, channelType: String, cid: String, reaction: StreamChatReaction) {
        self.createdAt = createdAt
        
        self.message = message
        
        self.type = type
        
        self.user = user
        
        self.team = team
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.reaction = reaction
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case message
        
        case type
        
        case user
        
        case team
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case reaction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(reaction, forKey: .reaction)
    }
}

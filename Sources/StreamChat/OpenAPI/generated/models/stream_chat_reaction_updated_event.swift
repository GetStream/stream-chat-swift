//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionUpdatedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var cid: String
    
    public var message: StreamChatMessage
    
    public var reaction: StreamChatReaction
    
    public var type: String
    
    public var channelId: String
    
    public init(createdAt: String, team: String?, user: StreamChatUserObject?, channelType: String, cid: String, message: StreamChatMessage, reaction: StreamChatReaction, type: String, channelId: String) {
        self.createdAt = createdAt
        
        self.team = team
        
        self.user = user
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.message = message
        
        self.reaction = reaction
        
        self.type = type
        
        self.channelId = channelId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case team
        
        case user
        
        case channelType = "channel_type"
        
        case cid
        
        case message
        
        case reaction
        
        case type
        
        case channelId = "channel_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
    }
}

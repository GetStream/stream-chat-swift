//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionUpdatedEvent: Codable, Hashable {
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage
    
    public var team: String?
    
    public var channelType: String
    
    public var reaction: StreamChatReaction
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public init(cid: String, createdAt: String, message: StreamChatMessage, team: String?, channelType: String, reaction: StreamChatReaction, type: String, user: StreamChatUserObject?, channelId: String) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.channelType = channelType
        
        self.reaction = reaction
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case channelType = "channel_type"
        
        case reaction
        
        case type
        
        case user
        
        case channelId = "channel_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
    }
}

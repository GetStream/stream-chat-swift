//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ReactionUpdatedEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var type: String
    
    public var message: Message
    
    public var reaction: Reaction
    
    public var team: String? = nil
    
    public var user: UserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, message: Message, reaction: Reaction, team: String? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.message = message
        
        self.reaction = reaction
        
        self.team = team
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case type
        
        case message
        
        case reaction
        
        case team
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
    }
}

extension ReactionUpdatedEvent: EventContainsCreationDate {}
extension ReactionUpdatedEvent: EventContainsUser {}

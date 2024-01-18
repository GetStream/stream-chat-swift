//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionNewEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var reaction: StreamChatReaction?
    
    public var team: String?
    
    public var type: String
    
    public var channelType: String
    
    public var message: StreamChatMessage?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public init(channelId: String, cid: String, createdAt: Date, reaction: StreamChatReaction?, team: String?, type: String, channelType: String, message: StreamChatMessage?, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?) {
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.reaction = reaction
        
        self.team = team
        
        self.type = type
        
        self.channelType = channelType
        
        self.message = message
        
        self.threadParticipants = threadParticipants
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
        
        case reaction
        
        case team
        
        case type
        
        case channelType = "channel_type"
        
        case message
        
        case threadParticipants = "thread_participants"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
    }
}

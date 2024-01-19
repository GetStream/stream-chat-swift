//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionDeletedEvent: Codable, Hashable, Event {
    public var channelType: String
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var reaction: StreamChatReaction?
    
    public var cid: String
    
    public init(channelType: String, createdAt: Date, message: StreamChatMessage?, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?, channelId: String, reaction: StreamChatReaction?, cid: String) {
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.reaction = reaction
        
        self.cid = cid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case reaction
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(cid, forKey: .cid)
    }
}

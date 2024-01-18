//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionDeletedEvent: Codable, Hashable, Event {
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var cid: String
    
    public var reaction: StreamChatReaction?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public init(team: String?, threadParticipants: [StreamChatUserObject]?, createdAt: Date, message: StreamChatMessage?, cid: String, reaction: StreamChatReaction?, type: String, user: StreamChatUserObject?, channelId: String, channelType: String) {
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.cid = cid
        
        self.reaction = reaction
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case team
        
        case threadParticipants = "thread_participants"
        
        case createdAt = "created_at"
        
        case message
        
        case cid
        
        case reaction
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionDeletedEvent: Codable, Hashable {
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var message: StreamChatMessage?
    
    public var createdAt: String
    
    public var reaction: StreamChatReaction?
    
    public var team: String?
    
    public var channelId: String
    
    public var cid: String
    
    public init(threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?, channelType: String, message: StreamChatMessage?, createdAt: String, reaction: StreamChatReaction?, team: String?, channelId: String, cid: String) {
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
        
        self.channelType = channelType
        
        self.message = message
        
        self.createdAt = createdAt
        
        self.reaction = reaction
        
        self.team = team
        
        self.channelId = channelId
        
        self.cid = cid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
        
        case channelType = "channel_type"
        
        case message
        
        case createdAt = "created_at"
        
        case reaction
        
        case team
        
        case channelId = "channel_id"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
    }
}

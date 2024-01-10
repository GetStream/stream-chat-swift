//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionNewEvent: Codable, Hashable {
    public var reaction: StreamChatReaction?
    
    public var user: StreamChatUserObject?
    
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var channelId: String
    
    public var channelType: String
    
    public init(reaction: StreamChatReaction?, user: StreamChatUserObject?, cid: String, createdAt: String, message: StreamChatMessage?, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, channelId: String, channelType: String) {
        self.reaction = reaction
        
        self.user = user
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reaction
        
        case user
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionNewEvent: Codable, Hashable {
    public var createdAt: String
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var cid: String
    
    public var channelType: String
    
    public var message: StreamChatMessage?
    
    public var reaction: StreamChatReaction?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var channelId: String
    
    public init(createdAt: String, type: String, user: StreamChatUserObject?, cid: String, channelType: String, message: StreamChatMessage?, reaction: StreamChatReaction?, team: String?, threadParticipants: [StreamChatUserObject]?, channelId: String) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
        
        self.cid = cid
        
        self.channelType = channelType
        
        self.message = message
        
        self.reaction = reaction
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.channelId = channelId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case user
        
        case cid
        
        case channelType = "channel_type"
        
        case message
        
        case reaction
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case channelId = "channel_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(channelId, forKey: .channelId)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionNewEvent: Codable, Hashable {
    public var createdAt: String
    
    public var reaction: StreamChatReaction?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public var cid: String
    
    public var channelType: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var type: String
    
    public var channelId: String
    
    public init(createdAt: String, reaction: StreamChatReaction?, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?, cid: String, channelType: String, message: StreamChatMessage?, team: String?, type: String, channelId: String) {
        self.createdAt = createdAt
        
        self.reaction = reaction
        
        self.threadParticipants = threadParticipants
        
        self.user = user
        
        self.cid = cid
        
        self.channelType = channelType
        
        self.message = message
        
        self.team = team
        
        self.type = type
        
        self.channelId = channelId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case reaction
        
        case threadParticipants = "thread_participants"
        
        case user
        
        case cid
        
        case channelType = "channel_type"
        
        case message
        
        case team
        
        case type
        
        case channelId = "channel_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
    }
}

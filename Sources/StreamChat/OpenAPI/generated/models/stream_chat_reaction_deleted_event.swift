//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionDeletedEvent: Codable, Hashable {
    public var reaction: StreamChatReaction?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var cid: String
    
    public var message: StreamChatMessage?
    
    public var type: String
    
    public var channelId: String
    
    public var createdAt: String
    
    public var team: String?
    
    public init(reaction: StreamChatReaction?, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?, channelType: String, cid: String, message: StreamChatMessage?, type: String, channelId: String, createdAt: String, team: String?) {
        self.reaction = reaction
        
        self.threadParticipants = threadParticipants
        
        self.user = user
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.message = message
        
        self.type = type
        
        self.channelId = channelId
        
        self.createdAt = createdAt
        
        self.team = team
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reaction
        
        case threadParticipants = "thread_participants"
        
        case user
        
        case channelType = "channel_type"
        
        case cid
        
        case message
        
        case type
        
        case channelId = "channel_id"
        
        case createdAt = "created_at"
        
        case team
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(team, forKey: .team)
    }
}

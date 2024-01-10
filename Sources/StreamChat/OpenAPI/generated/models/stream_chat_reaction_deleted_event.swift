//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionDeletedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var message: StreamChatMessage?
    
    public var reaction: StreamChatReaction?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(createdAt: String, channelId: String, channelType: String, cid: String, message: StreamChatMessage?, reaction: StreamChatReaction?, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?) {
        self.createdAt = createdAt
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.message = message
        
        self.reaction = reaction
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case message
        
        case reaction
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

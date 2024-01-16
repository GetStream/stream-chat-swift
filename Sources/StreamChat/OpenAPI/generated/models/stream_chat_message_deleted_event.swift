//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageDeletedEvent: Codable, Hashable, Event {
    public var team: String?
    
    public var channelType: String
    
    public var cid: String
    
    public var hardDelete: Bool
    
    public var message: StreamChatMessage?
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var createdAt: String
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public init(team: String?, channelType: String, cid: String, hardDelete: Bool, message: StreamChatMessage?, user: StreamChatUserObject?, channelId: String, createdAt: String, threadParticipants: [StreamChatUserObject]?, type: String) {
        self.team = team
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.hardDelete = hardDelete
        
        self.message = message
        
        self.user = user
        
        self.channelId = channelId
        
        self.createdAt = createdAt
        
        self.threadParticipants = threadParticipants
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case team
        
        case channelType = "channel_type"
        
        case cid
        
        case hardDelete = "hard_delete"
        
        case message
        
        case user
        
        case channelId = "channel_id"
        
        case createdAt = "created_at"
        
        case threadParticipants = "thread_participants"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
    }
}

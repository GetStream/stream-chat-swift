//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageDeletedEvent: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var hardDelete: Bool
    
    public var channelId: String
    
    public var user: StreamChatUserObject?
    
    public init(message: StreamChatMessage?, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, channelType: String, cid: String, createdAt: String, hardDelete: Bool, channelId: String, user: StreamChatUserObject?) {
        self.message = message
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.hardDelete = hardDelete
        
        self.channelId = channelId
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case hardDelete = "hard_delete"
        
        case channelId = "channel_id"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(user, forKey: .user)
    }
}

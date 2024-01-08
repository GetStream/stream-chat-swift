//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageDeletedEvent: Codable, Hashable {
    public var channelId: String
    
    public var createdAt: String
    
    public var hardDelete: Bool
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var cid: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public init(channelId: String, createdAt: String, hardDelete: Bool, type: String, user: StreamChatUserObject?, channelType: String, cid: String, message: StreamChatMessage?, team: String?, threadParticipants: [StreamChatUserObject]?) {
        self.channelId = channelId
        
        self.createdAt = createdAt
        
        self.hardDelete = hardDelete
        
        self.type = type
        
        self.user = user
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.message = message
        
        self.team = team
        
        self.threadParticipants = threadParticipants
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case createdAt = "created_at"
        
        case hardDelete = "hard_delete"
        
        case type
        
        case user
        
        case channelType = "channel_type"
        
        case cid
        
        case message
        
        case team
        
        case threadParticipants = "thread_participants"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
    }
}

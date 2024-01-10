//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageDeletedEvent: Codable, Hashable {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var message: StreamChatMessage?
    
    public var createdAt: String
    
    public var hardDelete: Bool
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(channelId: String, channelType: String, cid: String, message: StreamChatMessage?, createdAt: String, hardDelete: Bool, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.message = message
        
        self.createdAt = createdAt
        
        self.hardDelete = hardDelete
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case message
        
        case createdAt = "created_at"
        
        case hardDelete = "hard_delete"
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageDeletedEvent: Codable, Hashable, Event {
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var type: String
    
    public var channelId: String
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public var hardDelete: Bool
    
    public init(channelType: String, cid: String, createdAt: Date, message: StreamChatMessage?, type: String, channelId: String, team: String?, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?, hardDelete: Bool) {
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.type = type
        
        self.channelId = channelId
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.user = user
        
        self.hardDelete = hardDelete
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case type
        
        case channelId = "channel_id"
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case user
        
        case hardDelete = "hard_delete"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(hardDelete, forKey: .hardDelete)
    }
}

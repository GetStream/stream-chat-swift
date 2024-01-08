//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageUpdatedEvent: Codable, Hashable {
    public var channelId: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var channelType: String
    
    public var team: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(channelId: String, cid: String, createdAt: String, message: StreamChatMessage?, threadParticipants: [StreamChatUserObject]?, channelType: String, team: String?, type: String, user: StreamChatUserObject?) {
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.threadParticipants = threadParticipants
        
        self.channelType = channelType
        
        self.team = team
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case threadParticipants = "thread_participants"
        
        case channelType = "channel_type"
        
        case team
        
        case type
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

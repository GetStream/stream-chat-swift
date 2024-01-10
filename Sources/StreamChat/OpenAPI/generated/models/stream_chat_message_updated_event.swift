//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageUpdatedEvent: Codable, Hashable {
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var channelId: String
    
    public var cid: String
    
    public init(user: StreamChatUserObject?, channelType: String, createdAt: String, message: StreamChatMessage?, team: String?, threadParticipants: [StreamChatUserObject]?, type: String, channelId: String, cid: String) {
        self.user = user
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.channelId = channelId
        
        self.cid = cid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case channelId = "channel_id"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
    }
}

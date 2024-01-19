//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageUpdatedEvent: Codable, Hashable, Event {
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var type: String
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public init(threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?, createdAt: Date, message: StreamChatMessage?, team: String?, type: String, channelId: String, channelType: String, cid: String) {
        self.threadParticipants = threadParticipants
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.type = type
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case threadParticipants = "thread_participants"
        
        case user
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case type
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
    }
}

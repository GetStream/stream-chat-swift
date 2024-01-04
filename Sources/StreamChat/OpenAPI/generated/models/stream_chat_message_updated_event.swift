//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageUpdatedEvent: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: String
    
    public var cid: String
    
    public var team: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public init(message: StreamChatMessage?, type: String, user: StreamChatUserObject?, channelId: String, channelType: String, createdAt: String, cid: String, team: String?, threadParticipants: [StreamChatUserObject]?) {
        self.message = message
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.cid = cid
        
        self.team = team
        
        self.threadParticipants = threadParticipants
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case cid
        
        case team
        
        case threadParticipants = "thread_participants"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
    }
}

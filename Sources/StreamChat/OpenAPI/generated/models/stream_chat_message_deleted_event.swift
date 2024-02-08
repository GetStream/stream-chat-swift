//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageDeletedEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var hardDelete: Bool
    
    public var type: String
    
    public var team: String? = nil
    
    public var threadParticipants: [StreamChatUserObject]? = nil
    
    public var message: StreamChatMessage? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, hardDelete: Bool, type: String, team: String? = nil, threadParticipants: [StreamChatUserObject]? = nil, message: StreamChatMessage? = nil, user: StreamChatUserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.hardDelete = hardDelete
        
        self.type = type
        
        self.team = team
        
        self.threadParticipants = threadParticipants
        
        self.message = message
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case hardDelete = "hard_delete"
        
        case type
        
        case team
        
        case threadParticipants = "thread_participants"
        
        case message
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(user, forKey: .user)
    }
}

extension StreamChatMessageDeletedEvent: EventContainsCreationDate {}

extension StreamChatMessageDeletedEvent: EventContainsMessage {}

extension StreamChatMessageDeletedEvent: EventContainsUser {}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagUpdatedEvent: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdBy: StreamChatUserObject?
    
    public var createdAt: String
    
    public init(message: StreamChatMessage?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?, createdBy: StreamChatUserObject?, createdAt: String) {
        self.message = message
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
        
        self.createdBy = createdBy
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
        
        case createdBy = "CreatedBy"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

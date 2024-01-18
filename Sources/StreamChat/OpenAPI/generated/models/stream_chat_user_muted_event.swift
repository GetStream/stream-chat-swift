//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMutedEvent: Codable, Hashable, Event {
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var targetUser: String?
    
    public var targetUsers: [String]?
    
    public var type: String
    
    public init(user: StreamChatUserObject?, createdAt: Date, targetUser: String?, targetUsers: [String]?, type: String) {
        self.user = user
        
        self.createdAt = createdAt
        
        self.targetUser = targetUser
        
        self.targetUsers = targetUsers
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case createdAt = "created_at"
        
        case targetUser = "target_user"
        
        case targetUsers = "target_users"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(targetUsers, forKey: .targetUsers)
        
        try container.encode(type, forKey: .type)
    }
}

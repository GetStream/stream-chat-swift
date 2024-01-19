//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMutedEvent: Codable, Hashable, Event {
    public var targetUsers: [String]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var targetUser: String?
    
    public init(targetUsers: [String]?, type: String, user: StreamChatUserObject?, createdAt: Date, targetUser: String?) {
        self.targetUsers = targetUsers
        
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.targetUser = targetUser
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetUsers = "target_users"
        
        case type
        
        case user
        
        case createdAt = "created_at"
        
        case targetUser = "target_user"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(targetUsers, forKey: .targetUsers)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(targetUser, forKey: .targetUser)
    }
}

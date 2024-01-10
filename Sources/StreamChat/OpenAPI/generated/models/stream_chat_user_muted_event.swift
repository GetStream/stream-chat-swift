//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMutedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var targetUser: String?
    
    public var targetUsers: [String]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(createdAt: String, targetUser: String?, targetUsers: [String]?, type: String, user: StreamChatUserObject?) {
        self.createdAt = createdAt
        
        self.targetUser = targetUser
        
        self.targetUsers = targetUsers
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case targetUser = "target_user"
        
        case targetUsers = "target_users"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(targetUsers, forKey: .targetUsers)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

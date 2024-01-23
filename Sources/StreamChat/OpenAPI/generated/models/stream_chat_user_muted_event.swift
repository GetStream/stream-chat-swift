//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMutedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var type: String
    
    public var targetUser: String? = nil
    
    public var targetUsers: [String]? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(createdAt: Date, type: String, targetUser: String? = nil, targetUsers: [String]? = nil, user: StreamChatUserObject? = nil) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.targetUser = targetUser
        
        self.targetUsers = targetUsers
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case targetUser = "target_user"
        
        case targetUsers = "target_users"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(targetUsers, forKey: .targetUsers)
        
        try container.encode(user, forKey: .user)
    }
}

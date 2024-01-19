//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMemberResponse: Codable, Hashable {
    public var user: StreamChatUserResponse
    
    public var userId: String
    
    public var createdAt: Date
    
    public var custom: [String: RawJSON]
    
    public var deletedAt: Date?
    
    public var role: String?
    
    public var updatedAt: Date
    
    public init(user: StreamChatUserResponse, userId: String, createdAt: Date, custom: [String: RawJSON], deletedAt: Date?, role: String?, updatedAt: Date) {
        self.user = user
        
        self.userId = userId
        
        self.createdAt = createdAt
        
        self.custom = custom
        
        self.deletedAt = deletedAt
        
        self.role = role
        
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case userId = "user_id"
        
        case createdAt = "created_at"
        
        case custom
        
        case deletedAt = "deleted_at"
        
        case role
        
        case updatedAt = "updated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

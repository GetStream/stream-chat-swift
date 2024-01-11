//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReaction: Codable, Hashable {
    public var userId: String?
    
    public var custom: [String: RawJSON]?
    
    public var createdAt: String
    
    public var messageId: String
    
    public var score: Int
    
    public var type: String
    
    public var updatedAt: String
    
    public var user: StreamChatUserObject?
    
    public init(userId: String?, custom: [String: RawJSON], createdAt: String, messageId: String, score: Int, type: String, updatedAt: String, user: StreamChatUserObject?) {
        self.userId = userId
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.messageId = messageId
        
        self.score = score
        
        self.type = type
        
        self.updatedAt = updatedAt
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case custom
        
        case createdAt = "created_at"
        
        case messageId = "message_id"
        
        case score
        
        case type
        
        case updatedAt = "updated_at"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(score, forKey: .score)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
    }
}

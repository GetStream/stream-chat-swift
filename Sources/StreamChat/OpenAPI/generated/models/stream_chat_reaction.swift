//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReaction: Codable, Hashable {
    public var type: String
    
    public var updatedAt: Date
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var custom: [String: RawJSON]
    
    public var createdAt: Date
    
    public var messageId: String
    
    public var score: Int
    
    public init(type: String, updatedAt: Date, user: StreamChatUserObject?, userId: String?, custom: [String: RawJSON], createdAt: Date, messageId: String, score: Int) {
        self.type = type
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.userId = userId
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.messageId = messageId
        
        self.score = score
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case updatedAt = "updated_at"
        
        case user
        
        case userId = "user_id"
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case messageId = "message_id"
        
        case score
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(score, forKey: .score)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionRequest: Codable, Hashable {
    public var type: String
    
    public var messageId: String? = nil
    
    public var score: Int? = nil
    
    public var userId: String? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public var user: StreamChatUserObjectRequest? = nil
    
    public init(type: String, messageId: String? = nil, score: Int? = nil, userId: String? = nil, custom: [String: RawJSON]? = nil, user: StreamChatUserObjectRequest? = nil) {
        self.type = type
        
        self.messageId = messageId
        
        self.score = score
        
        self.userId = userId
        
        self.custom = custom
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case messageId = "message_id"
        
        case score
        
        case userId = "user_id"
        
        case custom
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(score, forKey: .score)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(user, forKey: .user)
    }
}

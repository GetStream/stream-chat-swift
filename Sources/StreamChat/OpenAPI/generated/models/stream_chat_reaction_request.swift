//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionRequest: Codable, Hashable {
    public var score: Int?
    
    public var type: String
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public var custom: [String: RawJSON]?
    
    public var messageId: String?
    
    public init(score: Int?, type: String, user: StreamChatUserObjectRequest?, userId: String?, custom: [String: RawJSON]?, messageId: String?) {
        self.score = score
        
        self.type = type
        
        self.user = user
        
        self.userId = userId
        
        self.custom = custom
        
        self.messageId = messageId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case score
        
        case type
        
        case user
        
        case userId = "user_id"
        
        case custom = "Custom"
        
        case messageId = "message_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(score, forKey: .score)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(messageId, forKey: .messageId)
    }
}

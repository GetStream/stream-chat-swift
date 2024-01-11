//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var messageId: String?
    
    public var score: Int?
    
    public var type: String
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(custom: [String: RawJSON]?, messageId: String?, score: Int?, type: String, user: StreamChatUserObjectRequest?, userId: String?) {
        self.custom = custom
        
        self.messageId = messageId
        
        self.score = score
        
        self.type = type
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case messageId = "message_id"
        
        case score
        
        case type
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(score, forKey: .score)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}

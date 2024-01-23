//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagRequest: Codable, Hashable {
    public var reason: String? = nil
    
    public var targetMessageId: String? = nil
    
    public var userId: String? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public var user: StreamChatUserObjectRequest? = nil
    
    public init(reason: String? = nil, targetMessageId: String? = nil, userId: String? = nil, custom: [String: RawJSON]? = nil, user: StreamChatUserObjectRequest? = nil) {
        self.reason = reason
        
        self.targetMessageId = targetMessageId
        
        self.userId = userId
        
        self.custom = custom
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
        
        case targetMessageId = "target_message_id"
        
        case userId = "user_id"
        
        case custom
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(user, forKey: .user)
    }
}

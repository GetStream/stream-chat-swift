//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var reason: String?
    
    public var targetMessageId: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(custom: [String: RawJSON]?, reason: String?, targetMessageId: String?, user: StreamChatUserObjectRequest?, userId: String?) {
        self.custom = custom
        
        self.reason = reason
        
        self.targetMessageId = targetMessageId
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case reason
        
        case targetMessageId = "target_message_id"
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteUserRequest: Codable, Hashable {
    public var targetIds: [String]
    
    public var timeout: Int? = nil
    
    public var userId: String? = nil
    
    public var user: StreamChatUserObjectRequest? = nil
    
    public init(targetIds: [String], timeout: Int? = nil, userId: String? = nil, user: StreamChatUserObjectRequest? = nil) {
        self.targetIds = targetIds
        
        self.timeout = timeout
        
        self.userId = userId
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
        
        case timeout
        
        case userId = "user_id"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(targetIds, forKey: .targetIds)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(user, forKey: .user)
    }
}

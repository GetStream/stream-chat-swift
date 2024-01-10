//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnmuteUserRequest: Codable, Hashable {
    public var timeout: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public var targetId: String
    
    public var targetIds: [String]
    
    public init(timeout: Int?, user: StreamChatUserObjectRequest?, userId: String?, targetId: String, targetIds: [String]) {
        self.timeout = timeout
        
        self.user = user
        
        self.userId = userId
        
        self.targetId = targetId
        
        self.targetIds = targetIds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case timeout
        
        case user
        
        case userId = "user_id"
        
        case targetId = "target_id"
        
        case targetIds = "target_ids"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(targetId, forKey: .targetId)
        
        try container.encode(targetIds, forKey: .targetIds)
    }
}

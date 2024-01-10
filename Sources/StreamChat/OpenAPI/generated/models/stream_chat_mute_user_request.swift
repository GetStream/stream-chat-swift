//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteUserRequest: Codable, Hashable {
    public var targetIds: [String]
    
    public var timeout: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(targetIds: [String], timeout: Int?, user: StreamChatUserObjectRequest?, userId: String?) {
        self.targetIds = targetIds
        
        self.timeout = timeout
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
        
        case timeout
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(targetIds, forKey: .targetIds)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}

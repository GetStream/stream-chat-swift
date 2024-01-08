//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteUserRequest: Codable, Hashable {
    public var userId: String?
    
    public var targetIds: [String]
    
    public var timeout: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public init(userId: String?, targetIds: [String], timeout: Int?, user: StreamChatUserObjectRequest?) {
        self.userId = userId
        
        self.targetIds = targetIds
        
        self.timeout = timeout
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case targetIds = "target_ids"
        
        case timeout
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(targetIds, forKey: .targetIds)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(user, forKey: .user)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMemberRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var role: String?
    
    public var userId: String
    
    public init(custom: [String: RawJSON]?, role: String?, userId: String) {
        self.custom = custom
        
        self.role = role
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case role
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(userId, forKey: .userId)
    }
}

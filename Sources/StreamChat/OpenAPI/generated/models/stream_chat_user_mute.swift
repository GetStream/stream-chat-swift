//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMute: Codable, Hashable {
    public var updatedAt: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var expires: String?
    
    public var target: StreamChatUserObject?
    
    public init(updatedAt: String, user: StreamChatUserObject?, createdAt: String, expires: String?, target: StreamChatUserObject?) {
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.expires = expires
        
        self.target = target
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "updated_at"
        
        case user
        
        case createdAt = "created_at"
        
        case expires
        
        case target
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(target, forKey: .target)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMute: Codable, Hashable {
    public var expires: String?
    
    public var target: StreamChatUserObject?
    
    public var updatedAt: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public init(expires: String?, target: StreamChatUserObject?, updatedAt: String, user: StreamChatUserObject?, createdAt: String) {
        self.expires = expires
        
        self.target = target
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case expires
        
        case target
        
        case updatedAt = "updated_at"
        
        case user
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(target, forKey: .target)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

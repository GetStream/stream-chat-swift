//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMute: Codable, Hashable {
    public var createdAt: Date
    
    public var expires: Date?
    
    public var target: StreamChatUserObject?
    
    public var updatedAt: Date
    
    public var user: StreamChatUserObject?
    
    public init(createdAt: Date, expires: Date?, target: StreamChatUserObject?, updatedAt: Date, user: StreamChatUserObject?) {
        self.createdAt = createdAt
        
        self.expires = expires
        
        self.target = target
        
        self.updatedAt = updatedAt
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case expires
        
        case target
        
        case updatedAt = "updated_at"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(target, forKey: .target)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
    }
}

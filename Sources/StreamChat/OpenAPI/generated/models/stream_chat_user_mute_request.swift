//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserMuteRequest: Codable, Hashable {
    public var createdAt: String?
    
    public var expires: String?
    
    public var target: StreamChatUserObjectRequest?
    
    public var updatedAt: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public init(createdAt: String?, expires: String?, target: StreamChatUserObjectRequest?, updatedAt: String?, user: StreamChatUserObjectRequest?) {
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

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserDeactivatedEvent: Codable, Hashable {
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var createdBy: StreamChatUserObject
    
    public init(type: String, user: StreamChatUserObject?, createdAt: String, createdBy: StreamChatUserObject) {
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.createdBy = createdBy
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case createdAt = "created_at"
        
        case createdBy = "created_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
    }
}

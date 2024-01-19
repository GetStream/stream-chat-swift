//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserUpdatedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(createdAt: Date, type: String, user: StreamChatUserObject?) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}
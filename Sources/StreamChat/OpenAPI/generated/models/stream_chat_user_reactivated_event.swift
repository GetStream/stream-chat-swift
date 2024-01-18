//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserReactivatedEvent: Codable, Hashable, Event {
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public init(type: String, user: StreamChatUserObject?, createdAt: Date) {
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

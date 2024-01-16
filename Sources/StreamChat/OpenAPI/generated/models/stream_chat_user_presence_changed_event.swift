//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserPresenceChangedEvent: Codable, Hashable, Event {
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var type: String
    
    public init(user: StreamChatUserObject?, createdAt: String, type: String) {
        self.user = user
        
        self.createdAt = createdAt
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case createdAt = "created_at"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
    }
}

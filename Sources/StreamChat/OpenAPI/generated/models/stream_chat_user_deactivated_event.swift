//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserDeactivatedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var type: String
    
    public var createdBy: StreamChatUserObject
    
    public var user: StreamChatUserObject? = nil
    
    public init(createdAt: Date, type: String, createdBy: StreamChatUserObject, user: StreamChatUserObject? = nil) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.createdBy = createdBy
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case createdBy = "created_by"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(user, forKey: .user)
    }
}

extension StreamChatUserDeactivatedEvent: EventContainsUser {}

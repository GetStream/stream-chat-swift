//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserDeactivatedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var createdBy: StreamChatUserObject
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(createdAt: String, createdBy: StreamChatUserObject, type: String, user: StreamChatUserObject?) {
        self.createdAt = createdAt
        
        self.createdBy = createdBy
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case createdBy = "created_by"
        
        case type
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

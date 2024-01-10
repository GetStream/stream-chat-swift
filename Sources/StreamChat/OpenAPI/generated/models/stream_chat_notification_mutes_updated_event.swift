//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMutesUpdatedEvent: Codable, Hashable {
    public var me: StreamChatOwnUser
    
    public var type: String
    
    public var createdAt: String
    
    public init(me: StreamChatOwnUser, type: String, createdAt: String) {
        self.me = me
        
        self.type = type
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case me
        
        case type
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMutesUpdatedEvent: Codable, Hashable, Event {
    public var type: String
    
    public var createdAt: Date
    
    public var me: StreamChatOwnUser
    
    public init(type: String, createdAt: Date, me: StreamChatOwnUser) {
        self.type = type
        
        self.createdAt = createdAt
        
        self.me = me
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case createdAt = "created_at"
        
        case me
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(me, forKey: .me)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMutesUpdatedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var me: StreamChatOwnUser
    
    public var type: String
    
    public init(createdAt: Date, me: StreamChatOwnUser, type: String) {
        self.createdAt = createdAt
        
        self.me = me
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case me
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(type, forKey: .type)
    }
}
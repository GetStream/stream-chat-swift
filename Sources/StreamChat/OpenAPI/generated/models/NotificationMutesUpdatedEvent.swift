//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationMutesUpdatedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var type: String
    
    public var me: OwnUser
    
    public init(createdAt: Date, type: String, me: OwnUser) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.me = me
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case me
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(me, forKey: .me)
    }
}

extension NotificationMutesUpdatedEvent: EventContainsCreationDate {}

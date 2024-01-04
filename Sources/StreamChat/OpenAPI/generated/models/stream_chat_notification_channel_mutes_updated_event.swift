//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationChannelMutesUpdatedEvent: Codable, Hashable {
    public var type: String
    
    public var createdAt: String
    
    public var me: StreamChatOwnUser
    
    public init(type: String, createdAt: String, me: StreamChatOwnUser) {
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

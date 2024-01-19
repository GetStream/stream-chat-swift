//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatConnectedEvent: Codable, Hashable, Event {
    public var connectionId: String
    
    public var createdAt: Date
    
    public var me: StreamChatOwnUserResponse
    
    public var type: String
    
    public init(connectionId: String, createdAt: Date, me: StreamChatOwnUserResponse, type: String) {
        self.connectionId = connectionId
        
        self.createdAt = createdAt
        
        self.me = me
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        
        case createdAt = "created_at"
        
        case me
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(type, forKey: .type)
    }
}
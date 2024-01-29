//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHealthCheckEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var connectionId: String
    
    public var createdAt: Date
    
    public var type: String
    
    public var me: StreamChatOwnUser? = nil
    
    public init(cid: String, connectionId: String, createdAt: Date, type: String, me: StreamChatOwnUser? = nil) {
        self.cid = cid
        
        self.connectionId = connectionId
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.me = me
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case connectionId = "connection_id"
        
        case createdAt = "created_at"
        
        case type
        
        case me
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(me, forKey: .me)
    }
}

extension StreamChatHealthCheckEvent: EventContainsCurrentUser {}

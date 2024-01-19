//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHealthCheckEvent: Codable, Hashable, Event {
    public var type: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var me: StreamChatOwnUser?
    
    public var connectionId: String
    
    public init(type: String, cid: String, createdAt: Date, me: StreamChatOwnUser?) {
        self.type = type
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.me = me
        
        connectionId = ""
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case cid
        
        case createdAt = "created_at"
        
        case me
        
        case connectionId = "connection_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(me, forKey: .me)
    }
}

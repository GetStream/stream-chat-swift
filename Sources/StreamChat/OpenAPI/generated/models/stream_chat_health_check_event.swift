//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHealthCheckEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var createdAt: String
    
    public var me: StreamChatOwnUser?
    
    public var type: String
    
    public var connectionId: String
    
    public init(cid: String, createdAt: String, me: StreamChatOwnUser?, type: String) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.me = me
        
        self.type = type
        
        connectionId = ""
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case me
        
        case type
     
        case connectionId = "connection_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(type, forKey: .type)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHealthCheckEvent: Codable, Hashable, Event {
    public var me: StreamChatOwnUser?
    
    public var type: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public init(me: StreamChatOwnUser?, type: String, cid: String, createdAt: Date) {
        self.me = me
        
        self.type = type
        
        self.cid = cid
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case me
        
        case type
        
        case cid
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

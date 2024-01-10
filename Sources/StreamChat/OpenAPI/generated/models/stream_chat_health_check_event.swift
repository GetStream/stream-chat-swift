//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHealthCheckEvent: Codable, Hashable {
    public var createdAt: String
    
    public var me: StreamChatOwnUser?
    
    public var type: String
    
    public var cid: String
    
    public init(createdAt: String, me: StreamChatOwnUser?, type: String, cid: String) {
        self.createdAt = createdAt
        
        self.me = me
        
        self.type = type
        
        self.cid = cid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case me
        
        case type
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(cid, forKey: .cid)
    }
}

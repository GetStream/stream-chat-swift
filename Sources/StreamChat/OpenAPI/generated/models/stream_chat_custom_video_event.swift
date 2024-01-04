//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCustomVideoEvent: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: String
    
    public var custom: [String: RawJSON]
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public init(callCid: String, createdAt: String, custom: [String: RawJSON], type: String, user: StreamChatUserResponse) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.custom = custom
        
        self.type = type
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case custom
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

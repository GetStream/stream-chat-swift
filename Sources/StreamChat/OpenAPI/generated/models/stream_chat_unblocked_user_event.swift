//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnblockedUserEvent: Codable, Hashable {
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public var callCid: String
    
    public var createdAt: String
    
    public init(type: String, user: StreamChatUserResponse, callCid: String, createdAt: String) {
        self.type = type
        
        self.user = user
        
        self.callCid = callCid
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

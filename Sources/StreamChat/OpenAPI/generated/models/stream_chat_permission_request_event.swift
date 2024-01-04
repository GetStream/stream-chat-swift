//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPermissionRequestEvent: Codable, Hashable {
    public var callCid: String
    
    public var createdAt: String
    
    public var permissions: [String]
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public init(callCid: String, createdAt: String, permissions: [String], type: String, user: StreamChatUserResponse) {
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.permissions = permissions
        
        self.type = type
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case permissions
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(permissions, forKey: .permissions)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

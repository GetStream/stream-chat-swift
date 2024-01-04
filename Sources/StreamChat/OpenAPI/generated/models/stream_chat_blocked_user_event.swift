//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBlockedUserEvent: Codable, Hashable {
    public var blockedByUser: StreamChatUserResponse?
    
    public var callCid: String
    
    public var createdAt: String
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public init(blockedByUser: StreamChatUserResponse?, callCid: String, createdAt: String, type: String, user: StreamChatUserResponse) {
        self.blockedByUser = blockedByUser
        
        self.callCid = callCid
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedByUser = "blocked_by_user"
        
        case callCid = "call_cid"
        
        case createdAt = "created_at"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blockedByUser, forKey: .blockedByUser)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

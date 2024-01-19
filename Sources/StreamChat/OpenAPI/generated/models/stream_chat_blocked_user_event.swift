//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBlockedUserEvent: Codable, Hashable {
    public var createdAt: Date
    
    public var type: String
    
    public var user: StreamChatUserResponse
    
    public var blockedByUser: StreamChatUserResponse?
    
    public var callCid: String
    
    public init(createdAt: Date, type: String, user: StreamChatUserResponse, blockedByUser: StreamChatUserResponse?, callCid: String) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
        
        self.blockedByUser = blockedByUser
        
        self.callCid = callCid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case user
        
        case blockedByUser = "blocked_by_user"
        
        case callCid = "call_cid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(blockedByUser, forKey: .blockedByUser)
        
        try container.encode(callCid, forKey: .callCid)
    }
}

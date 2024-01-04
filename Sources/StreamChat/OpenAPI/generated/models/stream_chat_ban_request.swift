//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanRequest: Codable, Hashable {
    public var user: StreamChatUserObjectRequest?
    
    public var bannedBy: StreamChatUserObjectRequest?
    
    public var ipBan: Bool?
    
    public var reason: String?
    
    public var targetUserId: String
    
    public var timeout: Int?
    
    public var bannedById: String?
    
    public var id: String?
    
    public var shadow: Bool?
    
    public var type: String?
    
    public var userId: String?
    
    public init(user: StreamChatUserObjectRequest?, bannedBy: StreamChatUserObjectRequest?, ipBan: Bool?, reason: String?, targetUserId: String, timeout: Int?, bannedById: String?, id: String?, shadow: Bool?, type: String?, userId: String?) {
        self.user = user
        
        self.bannedBy = bannedBy
        
        self.ipBan = ipBan
        
        self.reason = reason
        
        self.targetUserId = targetUserId
        
        self.timeout = timeout
        
        self.bannedById = bannedById
        
        self.id = id
        
        self.shadow = shadow
        
        self.type = type
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case bannedBy = "banned_by"
        
        case ipBan = "ip_ban"
        
        case reason
        
        case targetUserId = "target_user_id"
        
        case timeout
        
        case bannedById = "banned_by_id"
        
        case id
        
        case shadow
        
        case type
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(ipBan, forKey: .ipBan)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(targetUserId, forKey: .targetUserId)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(bannedById, forKey: .bannedById)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(userId, forKey: .userId)
    }
}

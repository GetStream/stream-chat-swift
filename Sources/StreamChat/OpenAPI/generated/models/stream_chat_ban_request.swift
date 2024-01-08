//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanRequest: Codable, Hashable {
    public var bannedBy: StreamChatUserObjectRequest?
    
    public var bannedById: String?
    
    public var id: String?
    
    public var ipBan: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public var reason: String?
    
    public var shadow: Bool?
    
    public var targetUserId: String
    
    public var timeout: Int?
    
    public var type: String?
    
    public var userId: String?
    
    public init(bannedBy: StreamChatUserObjectRequest?, bannedById: String?, id: String?, ipBan: Bool?, user: StreamChatUserObjectRequest?, reason: String?, shadow: Bool?, targetUserId: String, timeout: Int?, type: String?, userId: String?) {
        self.bannedBy = bannedBy
        
        self.bannedById = bannedById
        
        self.id = id
        
        self.ipBan = ipBan
        
        self.user = user
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.targetUserId = targetUserId
        
        self.timeout = timeout
        
        self.type = type
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bannedBy = "banned_by"
        
        case bannedById = "banned_by_id"
        
        case id
        
        case ipBan = "ip_ban"
        
        case user
        
        case reason
        
        case shadow
        
        case targetUserId = "target_user_id"
        
        case timeout
        
        case type
        
        case userId = "user_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(bannedById, forKey: .bannedById)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(ipBan, forKey: .ipBan)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(targetUserId, forKey: .targetUserId)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(userId, forKey: .userId)
    }
}

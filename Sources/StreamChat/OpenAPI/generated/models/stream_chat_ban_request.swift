//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanRequest: Codable, Hashable {
    public var bannedBy: StreamChatUserRequest?
    
    public var bannedById: String?
    
    public var ipBan: Bool?
    
    public var targetUserId: String
    
    public var timeout: Int?
    
    public var id: String?
    
    public var reason: String?
    
    public var shadow: Bool?
    
    public var type: String?
    
    public init(bannedBy: StreamChatUserRequest?, bannedById: String?, ipBan: Bool?, targetUserId: String, timeout: Int?, id: String?, reason: String?, shadow: Bool?, type: String?) {
        self.bannedBy = bannedBy
        
        self.bannedById = bannedById
        
        self.ipBan = ipBan
        
        self.targetUserId = targetUserId
        
        self.timeout = timeout
        
        self.id = id
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bannedBy = "banned_by"
        
        case bannedById = "banned_by_id"
        
        case ipBan = "ip_ban"
        
        case targetUserId = "target_user_id"
        
        case timeout
        
        case id
        
        case reason
        
        case shadow
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(bannedById, forKey: .bannedById)
        
        try container.encode(ipBan, forKey: .ipBan)
        
        try container.encode(targetUserId, forKey: .targetUserId)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(type, forKey: .type)
    }
}

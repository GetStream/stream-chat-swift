//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanRequest: Codable, Hashable {
    public var bannedBy: StreamChatUserRequest?
    
    public var reason: String?
    
    public var timeout: Int?
    
    public var shadow: Bool?
    
    public var targetUserId: String
    
    public var type: String?
    
    public var bannedById: String?
    
    public var id: String?
    
    public var ipBan: Bool?
    
    public init(bannedBy: StreamChatUserRequest?, reason: String?, timeout: Int?, shadow: Bool?, targetUserId: String, type: String?, bannedById: String?, id: String?, ipBan: Bool?) {
        self.bannedBy = bannedBy
        
        self.reason = reason
        
        self.timeout = timeout
        
        self.shadow = shadow
        
        self.targetUserId = targetUserId
        
        self.type = type
        
        self.bannedById = bannedById
        
        self.id = id
        
        self.ipBan = ipBan
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bannedBy = "banned_by"
        
        case reason
        
        case timeout
        
        case shadow
        
        case targetUserId = "target_user_id"
        
        case type
        
        case bannedById = "banned_by_id"
        
        case id
        
        case ipBan = "ip_ban"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(targetUserId, forKey: .targetUserId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(bannedById, forKey: .bannedById)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(ipBan, forKey: .ipBan)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanRequest: Codable, Hashable {
    public var ipBan: Bool?
    
    public var reason: String?
    
    public var targetUserId: String
    
    public var type: String?
    
    public var timeout: Int?
    
    public var bannedBy: StreamChatUserRequest?
    
    public var bannedById: String?
    
    public var id: String?
    
    public var shadow: Bool?
    
    public init(ipBan: Bool?, reason: String?, targetUserId: String, type: String?, timeout: Int?, bannedBy: StreamChatUserRequest?, bannedById: String?, id: String?, shadow: Bool?) {
        self.ipBan = ipBan
        
        self.reason = reason
        
        self.targetUserId = targetUserId
        
        self.type = type
        
        self.timeout = timeout
        
        self.bannedBy = bannedBy
        
        self.bannedById = bannedById
        
        self.id = id
        
        self.shadow = shadow
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case ipBan = "ip_ban"
        
        case reason
        
        case targetUserId = "target_user_id"
        
        case type
        
        case timeout
        
        case bannedBy = "banned_by"
        
        case bannedById = "banned_by_id"
        
        case id
        
        case shadow
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(ipBan, forKey: .ipBan)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(targetUserId, forKey: .targetUserId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(bannedById, forKey: .bannedById)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(shadow, forKey: .shadow)
    }
}

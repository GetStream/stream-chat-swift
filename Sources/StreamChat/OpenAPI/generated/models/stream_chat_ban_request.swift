//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanRequest: Codable, Hashable {
    public var targetUserId: String
    
    public var bannedById: String? = nil
    
    public var id: String? = nil
    
    public var ipBan: Bool? = nil
    
    public var reason: String? = nil
    
    public var shadow: Bool? = nil
    
    public var timeout: Int? = nil
    
    public var type: String? = nil
    
    public var bannedBy: StreamChatUserRequest? = nil
    
    public init(targetUserId: String, bannedById: String? = nil, id: String? = nil, ipBan: Bool? = nil, reason: String? = nil, shadow: Bool? = nil, timeout: Int? = nil, type: String? = nil, bannedBy: StreamChatUserRequest? = nil) {
        self.targetUserId = targetUserId
        
        self.bannedById = bannedById
        
        self.id = id
        
        self.ipBan = ipBan
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.timeout = timeout
        
        self.type = type
        
        self.bannedBy = bannedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetUserId = "target_user_id"
        
        case bannedById = "banned_by_id"
        
        case id
        
        case ipBan = "ip_ban"
        
        case reason
        
        case shadow
        
        case timeout
        
        case type
        
        case bannedBy = "banned_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(targetUserId, forKey: .targetUserId)
        
        try container.encode(bannedById, forKey: .bannedById)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(ipBan, forKey: .ipBan)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(timeout, forKey: .timeout)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(bannedBy, forKey: .bannedBy)
    }
}

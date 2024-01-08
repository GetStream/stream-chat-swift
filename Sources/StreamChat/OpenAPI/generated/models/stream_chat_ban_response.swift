//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanResponse: Codable, Hashable {
    public var bannedBy: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var createdAt: String
    
    public var expires: String?
    
    public var reason: String?
    
    public var shadow: Bool?
    
    public var user: StreamChatUserObject?
    
    public init(bannedBy: StreamChatUserObject?, channel: StreamChatChannelResponse?, createdAt: String, expires: String?, reason: String?, shadow: Bool?, user: StreamChatUserObject?) {
        self.bannedBy = bannedBy
        
        self.channel = channel
        
        self.createdAt = createdAt
        
        self.expires = expires
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bannedBy = "banned_by"
        
        case channel
        
        case createdAt = "created_at"
        
        case expires
        
        case reason
        
        case shadow
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(user, forKey: .user)
    }
}

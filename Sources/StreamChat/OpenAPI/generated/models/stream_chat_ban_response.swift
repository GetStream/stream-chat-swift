//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBanResponse: Codable, Hashable {
    public var createdAt: Date
    
    public var expires: Date? = nil
    
    public var reason: String? = nil
    
    public var shadow: Bool? = nil
    
    public var bannedBy: StreamChatUserObject? = nil
    
    public var channel: StreamChatChannelResponse? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(createdAt: Date, expires: Date? = nil, reason: String? = nil, shadow: Bool? = nil, bannedBy: StreamChatUserObject? = nil, channel: StreamChatChannelResponse? = nil, user: StreamChatUserObject? = nil) {
        self.createdAt = createdAt
        
        self.expires = expires
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.bannedBy = bannedBy
        
        self.channel = channel
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case expires
        
        case reason
        
        case shadow
        
        case bannedBy = "banned_by"
        
        case channel
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(bannedBy, forKey: .bannedBy)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(user, forKey: .user)
    }
}

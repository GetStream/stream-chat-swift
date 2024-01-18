//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMute: Codable, Hashable {
    public var updatedAt: Date
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var createdAt: Date
    
    public var expires: Date?
    
    public init(updatedAt: Date, user: StreamChatUserObject?, channel: StreamChatChannelResponse?, createdAt: Date, expires: Date?) {
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.channel = channel
        
        self.createdAt = createdAt
        
        self.expires = expires
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "updated_at"
        
        case user
        
        case channel
        
        case createdAt = "created_at"
        
        case expires
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
    }
}

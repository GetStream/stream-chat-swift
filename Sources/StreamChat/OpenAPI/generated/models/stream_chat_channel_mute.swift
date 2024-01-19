//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMute: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var createdAt: Date
    
    public var expires: Date?
    
    public var updatedAt: Date
    
    public var user: StreamChatUserObject?
    
    public init(channel: StreamChatChannelResponse?, createdAt: Date, expires: Date?, updatedAt: Date, user: StreamChatUserObject?) {
        self.channel = channel
        
        self.createdAt = createdAt
        
        self.expires = expires
        
        self.updatedAt = updatedAt
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case createdAt = "created_at"
        
        case expires
        
        case updatedAt = "updated_at"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMute: Codable, Hashable {
    public var createdAt: Date
    
    public var updatedAt: Date
    
    public var expires: Date? = nil
    
    public var channel: StreamChatChannelResponse? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(createdAt: Date, updatedAt: Date, expires: Date? = nil, channel: StreamChatChannelResponse? = nil, user: StreamChatUserObject? = nil) {
        self.createdAt = createdAt
        
        self.updatedAt = updatedAt
        
        self.expires = expires
        
        self.channel = channel
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case updatedAt = "updated_at"
        
        case expires
        
        case channel
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(user, forKey: .user)
    }
}

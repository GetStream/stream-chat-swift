//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMute: Codable, Hashable {
    public var createdAt: String
    
    public var expires: String?
    
    public var updatedAt: String
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public init(createdAt: String, expires: String?, updatedAt: String, user: StreamChatUserObject?, channel: StreamChatChannelResponse?) {
        self.createdAt = createdAt
        
        self.expires = expires
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.channel = channel
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case expires
        
        case updatedAt = "updated_at"
        
        case user
        
        case channel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expires, forKey: .expires)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
    }
}

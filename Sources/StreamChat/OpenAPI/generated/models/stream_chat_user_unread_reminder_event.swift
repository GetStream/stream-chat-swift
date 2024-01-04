//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserUnreadReminderEvent: Codable, Hashable {
    public var channels: [String: RawJSON]
    
    public var createdAt: String
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(channels: [String: RawJSON], createdAt: String, type: String, user: StreamChatUserObject?) {
        self.channels = channels
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channels
        
        case createdAt = "created_at"
        
        case type
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channels, forKey: .channels)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}

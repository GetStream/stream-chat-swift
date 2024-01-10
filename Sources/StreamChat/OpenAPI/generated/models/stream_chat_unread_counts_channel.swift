//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnreadCountsChannel: Codable, Hashable {
    public var lastRead: String
    
    public var unreadCount: Int
    
    public var channelId: String
    
    public init(lastRead: String, unreadCount: Int, channelId: String) {
        self.lastRead = lastRead
        
        self.unreadCount = unreadCount
        
        self.channelId = channelId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastRead = "last_read"
        
        case unreadCount = "unread_count"
        
        case channelId = "channel_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastRead, forKey: .lastRead)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channelId, forKey: .channelId)
    }
}

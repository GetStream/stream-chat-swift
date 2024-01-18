//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnreadCountsChannel: Codable, Hashable {
    public var unreadCount: Int
    
    public var channelId: String
    
    public var lastRead: Date
    
    public init(unreadCount: Int, channelId: String, lastRead: Date) {
        self.unreadCount = unreadCount
        
        self.channelId = channelId
        
        self.lastRead = lastRead
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unreadCount = "unread_count"
        
        case channelId = "channel_id"
        
        case lastRead = "last_read"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(lastRead, forKey: .lastRead)
    }
}

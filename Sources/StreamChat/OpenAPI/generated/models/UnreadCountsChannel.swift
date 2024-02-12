//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnreadCountsChannel: Codable, Hashable {
    public var channelId: String
    
    public var lastRead: Date
    
    public var unreadCount: Int
    
    public init(channelId: String, lastRead: Date, unreadCount: Int) {
        self.channelId = channelId
        
        self.lastRead = lastRead
        
        self.unreadCount = unreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case lastRead = "last_read"
        
        case unreadCount = "unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(lastRead, forKey: .lastRead)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnreadCountsChannelType: Codable, Hashable {
    public var channelCount: Int
    
    public var channelType: String
    
    public var unreadCount: Int
    
    public init(channelCount: Int, channelType: String, unreadCount: Int) {
        self.channelCount = channelCount
        
        self.channelType = channelType
        
        self.unreadCount = unreadCount
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCount = "channel_count"
        
        case channelType = "channel_type"
        
        case unreadCount = "unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelCount, forKey: .channelCount)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}

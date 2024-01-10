//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnreadCountsResponse: Codable, Hashable {
    public var channelType: [StreamChatUnreadCountsChannelType]
    
    public var channels: [StreamChatUnreadCountsChannel]
    
    public var duration: String
    
    public var totalUnreadCount: Int
    
    public init(channelType: [StreamChatUnreadCountsChannelType], channels: [StreamChatUnreadCountsChannel], duration: String, totalUnreadCount: Int) {
        self.channelType = channelType
        
        self.channels = channels
        
        self.duration = duration
        
        self.totalUnreadCount = totalUnreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case channels
        
        case duration
        
        case totalUnreadCount = "total_unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(channels, forKey: .channels)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnreadCountsResponse: Codable, Hashable {
    public var duration: String
    
    public var totalUnreadCount: Int
    
    public var channelType: [StreamChatUnreadCountsChannelType]
    
    public var channels: [StreamChatUnreadCountsChannel]
    
    public init(duration: String, totalUnreadCount: Int, channelType: [StreamChatUnreadCountsChannelType], channels: [StreamChatUnreadCountsChannel]) {
        self.duration = duration
        
        self.totalUnreadCount = totalUnreadCount
        
        self.channelType = channelType
        
        self.channels = channels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case totalUnreadCount = "total_unread_count"
        
        case channelType = "channel_type"
        
        case channels
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(channels, forKey: .channels)
    }
}

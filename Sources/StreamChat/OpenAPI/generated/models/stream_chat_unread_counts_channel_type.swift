//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnreadCountsChannelType: Codable, Hashable {
    public var channelType: String
    
    public var unreadCount: Int
    
    public var channelCount: Int
    
    public init(channelType: String, unreadCount: Int, channelCount: Int) {
        self.channelType = channelType
        
        self.unreadCount = unreadCount
        
        self.channelCount = channelCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case unreadCount = "unread_count"
        
        case channelCount = "channel_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channelCount, forKey: .channelCount)
    }
}

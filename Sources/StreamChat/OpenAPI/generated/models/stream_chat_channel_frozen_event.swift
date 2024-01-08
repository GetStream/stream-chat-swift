//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelFrozenEvent: Codable, Hashable {
    public var cid: String
    
    public var createdAt: String
    
    public var type: String
    
    public var channelId: String
    
    public var channelType: String
    
    public init(cid: String, createdAt: String, type: String, channelId: String, channelType: String) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case type
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}

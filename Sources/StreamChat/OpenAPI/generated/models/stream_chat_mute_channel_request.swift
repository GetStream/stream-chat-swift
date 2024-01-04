//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteChannelRequest: Codable, Hashable {
    public var channelCids: [String]
    
    public var expiration: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(channelCids: [String], expiration: Int?, user: StreamChatUserObjectRequest?, userId: String?) {
        self.channelCids = channelCids
        
        self.expiration = expiration
        
        self.user = user
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        
        case expiration
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelCids, forKey: .channelCids)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MuteChannelRequest: Codable, Hashable {
    public var channelCids: [String]
    
    public var expiration: Int? = nil
    
    public var userId: String? = nil
    
    public var user: UserObjectRequest? = nil
    
    public init(channelCids: [String], expiration: Int? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.channelCids = channelCids
        
        self.expiration = expiration
        
        self.userId = userId
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        
        case expiration
        
        case userId = "user_id"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelCids, forKey: .channelCids)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(user, forKey: .user)
    }
}

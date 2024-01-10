//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnmuteChannelRequest: Codable, Hashable {
    public var channelCid: String
    
    public var channelCids: [String]
    
    public var expiration: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(channelCid: String, channelCids: [String], expiration: Int?, user: StreamChatUserObjectRequest?, userId: String?) {
        self.channelCid = channelCid
        
        self.channelCids = channelCids
        
        self.expiration = expiration
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        
        case channelCids = "channel_cids"
        
        case expiration
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelCid, forKey: .channelCid)
        
        try container.encode(channelCids, forKey: .channelCids)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}

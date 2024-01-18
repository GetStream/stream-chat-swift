//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnmuteChannelRequest: Codable, Hashable {
    public var expiration: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public var channelCid: String
    
    public var channelCids: [String]
    
    public init(expiration: Int?, user: StreamChatUserObjectRequest?, userId: String?, channelCid: String, channelCids: [String]) {
        self.expiration = expiration
        
        self.user = user
        
        self.userId = userId
        
        self.channelCid = channelCid
        
        self.channelCids = channelCids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case expiration
        
        case user
        
        case userId = "user_id"
        
        case channelCid = "channel_cid"
        
        case channelCids = "channel_cids"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(channelCid, forKey: .channelCid)
        
        try container.encode(channelCids, forKey: .channelCids)
    }
}

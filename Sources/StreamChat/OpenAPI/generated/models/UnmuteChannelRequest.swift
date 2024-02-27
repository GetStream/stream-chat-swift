//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnmuteChannelRequest: Codable, Hashable {
    public var channelCid: String
    public var channelCids: [String]
    public var expiration: Int? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(channelCid: String, channelCids: [String], expiration: Int? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.channelCid = channelCid
        self.channelCids = channelCids
        self.expiration = expiration
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case channelCids = "channel_cids"
        case expiration
        case userId = "user_id"
        case user
    }
}
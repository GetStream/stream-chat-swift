//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MuteChannelRequest: Codable, Hashable {
    public var channelCids: [String]
    public var expiration: Int? = nil

    public init(channelCids: [String], expiration: Int? = nil) {
        self.channelCids = channelCids
        self.expiration = expiration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        case expiration
    }
}

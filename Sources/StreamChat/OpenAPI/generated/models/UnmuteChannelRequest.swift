//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnmuteChannelRequest: Codable, Hashable {
    public var expiration: Int? = nil
    public var channelCids: [String]? = nil

    public init(expiration: Int? = nil, channelCids: [String]? = nil) {
        self.expiration = expiration
        self.channelCids = channelCids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case expiration
        case channelCids = "channel_cids"
    }
}

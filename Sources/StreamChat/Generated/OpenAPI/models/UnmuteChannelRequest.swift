//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnmuteChannelRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Channel CIDs to mute (if multiple channels)
    var channelCids: [String]?
    /// Duration of mute in milliseconds
    var expiration: Int?

    init(channelCids: [String]? = nil, expiration: Int? = nil) {
        self.channelCids = channelCids
        self.expiration = expiration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        case expiration
    }

    static func == (lhs: UnmuteChannelRequest, rhs: UnmuteChannelRequest) -> Bool {
        lhs.channelCids == rhs.channelCids &&
            lhs.expiration == rhs.expiration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCids)
        hasher.combine(expiration)
    }
}

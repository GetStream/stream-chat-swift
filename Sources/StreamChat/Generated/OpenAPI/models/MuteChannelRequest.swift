//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class MuteChannelRequest: Sendable, Encodable, JSONEncodable {
    /// Channel CIDs to mute (if multiple channels)
    let channelCids: [String]?
    /// Duration of mute in milliseconds
    let expiration: Int?

    init(channelCids: [String]? = nil, expiration: Int? = nil) {
        self.channelCids = channelCids
        self.expiration = expiration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCids = "channel_cids"
        case expiration
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteChannelRequest: Sendable, Encodable, JSONEncodable {
    /// Channel CIDs to mute (if multiple channels)
    let channelCids: [String]?
    /// Duration of mute in milliseconds
    let expiration: Int?

    init(channelCids: [String]? = nil, expiration: Int? = nil) {
        self.channelCids = channelCids
        self.expiration = expiration
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(channelCids, forKey: .channelCids)
        try container.encodeIfPresent(expiration, forKey: .expiration)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnmuteChannelRequest: Sendable, Encodable, JSONEncodable {
    /// Channel CIDs to mute (if multiple channels)
    let channelCids: [String]?

    init(channelCids: [String]? = nil) {
        self.channelCids = channelCids
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(channelCids, forKey: .channelCids)
    }
}

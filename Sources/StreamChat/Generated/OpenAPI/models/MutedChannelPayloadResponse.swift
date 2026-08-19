//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MutedChannelPayloadResponse: Sendable, Codable, JSONEncodable {
    let channelMute: MutedChannelPayload?

    init(channelMute: MutedChannelPayload? = nil) {
        self.channelMute = channelMute
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMute = "channel_mute"
    }
}

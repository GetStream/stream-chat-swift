//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MutedChannelPayloadResponse: Sendable, Decodable {
    let channelMute: MutedChannelPayload?

    init(channelMute: MutedChannelPayload? = nil) {
        self.channelMute = channelMute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channelMute = try container.decodeIfPresent(
            MutedChannelPayload.self,
            forKey: .channelMute
        )
    }
}

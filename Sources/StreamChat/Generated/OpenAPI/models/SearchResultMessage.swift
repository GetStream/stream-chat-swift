//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResultMessage: Sendable, Decodable {
    let message: MessageResponse
    /// Represents channel in chat
    let channel: ChannelDetailPayload?

    init(message: MessageResponse, channel: ChannelDetailPayload? = nil) {
        self.message = message
        self.channel = channel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.message = try MessageResponse(from: decoder)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
    }
}

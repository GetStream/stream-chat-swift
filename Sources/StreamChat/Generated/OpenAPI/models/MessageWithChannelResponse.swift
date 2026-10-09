//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents any chat message
final class MessageWithChannelResponse: Sendable, Decodable {
    let message: MessageResponse
    /// Represents channel in chat
    let channel: ChannelDetailPayload

    init(message: MessageResponse, channel: ChannelDetailPayload) {
        self.message = message
        self.channel = channel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.message = try MessageResponse(from: decoder)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
    }
}

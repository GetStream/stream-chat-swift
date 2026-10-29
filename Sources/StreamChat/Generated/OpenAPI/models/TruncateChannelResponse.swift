//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TruncateChannelResponse: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// Represents any chat message
    let message: MessageResponse?

    init(channel: ChannelDetailPayload? = nil, message: MessageResponse? = nil) {
        self.channel = channel
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.message = try container.decodeIfPresent(MessageResponse.self, forKey: .message)
    }
}

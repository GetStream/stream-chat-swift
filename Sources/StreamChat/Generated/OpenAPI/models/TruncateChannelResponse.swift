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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case message
    }
}

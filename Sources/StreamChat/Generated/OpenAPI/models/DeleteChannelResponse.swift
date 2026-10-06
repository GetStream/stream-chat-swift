//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class DeleteChannelResponse: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?

    init(channel: ChannelDetailPayload? = nil) {
        self.channel = channel
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
    }
}

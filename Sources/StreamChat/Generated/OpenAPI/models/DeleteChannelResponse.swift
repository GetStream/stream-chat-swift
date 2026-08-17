//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteChannelResponse: Sendable, Codable, JSONEncodable {
    let channel: ChannelDetailPayload?

    init(channel: ChannelDetailPayload? = nil) {
        self.channel = channel
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
    }
}

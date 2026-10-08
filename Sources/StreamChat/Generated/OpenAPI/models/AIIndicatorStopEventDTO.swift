//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when the AI indicator is stopped.
final class AIIndicatorStopEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "ai_indicator.stop" in this case
    let type: String

    init(cid: ChannelId? = nil, createdAt: Date, type: String = "ai_indicator.stop") {
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

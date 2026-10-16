//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when client lost access to the channel and was unsubscribed from its events by server.
final class ChannelKickedEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel which was kicked
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "channel.kicked" in this case
    let type: String

    init(cid: ChannelId, createdAt: Date, type: String = "channel.kicked") {
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

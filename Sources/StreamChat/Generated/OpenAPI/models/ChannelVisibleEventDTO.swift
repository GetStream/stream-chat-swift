//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel is successfully shown.
final class ChannelVisibleEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The CID of the channel which was shown
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "channel.visible" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        cid: ChannelId,
        createdAt: Date,
        type: String = "channel.visible",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

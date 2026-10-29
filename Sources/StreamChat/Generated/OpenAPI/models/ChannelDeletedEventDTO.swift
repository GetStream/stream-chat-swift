//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel is successfully deleted.
final class ChannelDeletedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "channel.deleted" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        createdAt: Date,
        type: String = "channel.deleted",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

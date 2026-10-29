//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel is successfully hidden.
final class ChannelHiddenEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The CID of the channel which was hidden
    let cid: ChannelId
    /// Whether the history was cleared
    let clearHistory: Bool?
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "channel.hidden" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        cid: ChannelId,
        clearHistory: Bool? = nil,
        createdAt: Date,
        type: String = "channel.hidden",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.clearHistory = clearHistory
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.clearHistory = try container.decodeIfPresent(Bool.self, forKey: .clearHistory)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

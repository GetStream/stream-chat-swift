//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case type
        case user
    }
}

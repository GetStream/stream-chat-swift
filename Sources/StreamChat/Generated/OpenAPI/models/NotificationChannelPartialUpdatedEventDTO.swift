//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sent to channel members who are not watching after a partial update. Watching connections receive channel.updated instead.
final class NotificationChannelPartialUpdatedEventDTO: Sendable, Event, Decodable {
    /// Basic channel data and the complete custom data after a partial update.
    let channel: ChannelPartialUpdateResponse
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "notification.channel_partial_updated" in this case
    let type: String

    init(
        channel: ChannelPartialUpdateResponse,
        createdAt: Date,
        type: String = "notification.channel_partial_updated"
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelPartialUpdateResponse.self, forKey: .channel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

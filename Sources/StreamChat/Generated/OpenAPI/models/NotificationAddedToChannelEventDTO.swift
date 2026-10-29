//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sent to a user when they are added to a channel (as a personal notification to update their channel list).
final class NotificationAddedToChannelEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// Date/time of creation
    let createdAt: Date
    let member: MemberPayload
    /// The type of event: "notification.added_to_channel" in this case
    let type: String

    init(
        channel: ChannelDetailPayload,
        createdAt: Date,
        member: MemberPayload,
        type: String = "notification.added_to_channel"
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.member = member
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.member = try container.decode(MemberPayload.self, forKey: .member)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

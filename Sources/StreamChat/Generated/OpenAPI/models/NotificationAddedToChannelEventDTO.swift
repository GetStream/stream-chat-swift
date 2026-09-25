//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case member
        case type
    }
}

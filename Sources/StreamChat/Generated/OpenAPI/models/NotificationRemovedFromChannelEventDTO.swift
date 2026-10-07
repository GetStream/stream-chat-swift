//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sent to a user when they are removed from a channel (as a personal notification to update their channel list).
final class NotificationRemovedFromChannelEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The CID of the channel from which the user was removed
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let member: MemberPayload
    /// The type of event: "notification.removed_from_channel" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        cid: ChannelId,
        createdAt: Date,
        member: MemberPayload,
        type: String = "notification.removed_from_channel",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.member = member
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.member = try container.decode(MemberPayload.self, forKey: .member)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

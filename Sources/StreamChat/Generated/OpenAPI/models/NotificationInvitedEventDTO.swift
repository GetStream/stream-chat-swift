//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationInvitedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The CID of the channel to which the user was invited
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let member: MemberPayload
    /// The type of event: "notification.invited" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        cid: ChannelId,
        createdAt: Date,
        member: MemberPayload,
        type: String = "notification.invited",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.member = member
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case cid
        case createdAt = "created_at"
        case member
        case type
        case user
    }
}

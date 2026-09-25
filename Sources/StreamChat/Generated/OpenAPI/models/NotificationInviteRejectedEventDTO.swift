//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationInviteRejectedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// Date/time of creation
    let createdAt: Date
    let member: MemberPayload
    /// The type of event: "notification.invite_rejected" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        createdAt: Date,
        member: MemberPayload,
        type: String = "notification.invite_rejected",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.member = member
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case member
        case type
        case user
    }
}

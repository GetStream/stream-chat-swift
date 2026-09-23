//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberUpdatedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The CID of the channel in which the member was updated
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let member: MemberPayload
    /// The type of event: "member.updated" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId,
        createdAt: Date,
        member: MemberPayload,
        type: String = "member.updated",
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

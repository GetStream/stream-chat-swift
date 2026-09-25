//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TypingStopEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel where the user stopped typing
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let member: MemberInfoPayload?
    /// The parent ID if the user stopped typing in a thread
    let parentId: String?
    /// The type of event: "typing.stop" in this case
    let type: String
    let user: UserPayload?

    init(
        cid: ChannelId,
        createdAt: Date,
        member: MemberInfoPayload? = nil,
        parentId: String? = nil,
        type: String = "typing.stop",
        user: UserPayload? = nil
    ) {
        self.cid = cid
        self.createdAt = createdAt
        self.member = member
        self.parentId = parentId
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case member
        case parentId = "parent_id"
        case type
        case user
    }
}

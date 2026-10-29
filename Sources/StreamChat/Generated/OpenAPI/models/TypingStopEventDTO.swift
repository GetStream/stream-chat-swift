//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a user stops typing in a channel/thread.
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.member = try container.decodeIfPresent(MemberInfoPayload.self, forKey: .member)
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TypingStartEventDTO: Sendable, Event, Decodable {
    /// The ID of the channel where the user started typing
    let channelId: String?
    /// The type of the channel where the user started typing
    let channelType: String?
    /// The CID of the channel where the user started typing
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let member: MemberInfoPayload?
    /// The parent ID if the user started typing in a thread
    let parentId: String?
    let receivedAt: Date?
    /// The type of event: "typing.start" in this case
    let type: String
    let user: UserPayload?

    init(
        channelId: String? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        member: MemberInfoPayload? = nil,
        parentId: String? = nil,
        receivedAt: Date? = nil,
        type: String = "typing.start",
        user: UserPayload? = nil
    ) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.member = member
        self.parentId = parentId
        self.receivedAt = receivedAt
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case member
        case parentId = "parent_id"
        case receivedAt = "received_at"
        case type
        case user
    }
}

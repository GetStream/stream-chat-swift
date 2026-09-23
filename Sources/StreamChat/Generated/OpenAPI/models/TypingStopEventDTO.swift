//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TypingStopEventDTO: Sendable, Event, Decodable {
    /// The ID of the channel where the user stopped typing
    let channelId: String?
    /// The type of the channel where the user stopped typing
    let channelType: String?
    /// The CID of the channel where the user stopped typing
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let member: MemberInfoPayload?
    /// The parent ID if the user stopped typing in a thread
    let parentId: String?
    let receivedAt: Date?
    /// The type of event: "typing.stop" in this case
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
        type: String = "typing.stop",
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

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserMessagesDeletedEventDTO: Sendable, Event, Decodable {
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the target user's messages were deleted
    let channelId: String?
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel where the target user's messages were deleted
    let channelType: String?
    /// The CID of the channel where the target user's messages were deleted
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// Whether Messages were hard deleted
    let hardDelete: Bool?
    let receivedAt: Date?
    /// The team of the channel where the target user's messages were deleted
    let team: String?
    /// The type of event: "user.messages.deleted" in this case
    let type: String
    let user: UserPayload

    init(
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        hardDelete: Bool? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        type: String = "user.messages.deleted",
        user: UserPayload
    ) {
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.hardDelete = hardDelete
        self.receivedAt = receivedAt
        self.team = team
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCustom = "channel_custom"
        case channelId = "channel_id"
        case channelMemberCount = "channel_member_count"
        case channelMessageCount = "channel_message_count"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case hardDelete = "hard_delete"
        case receivedAt = "received_at"
        case team
        case type
        case user
    }
}

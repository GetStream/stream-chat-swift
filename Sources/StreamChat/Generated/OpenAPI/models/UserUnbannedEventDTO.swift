//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserUnbannedEventDTO: Sendable, Event, Decodable {
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the target user was unbanned
    let channelId: String?
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel where the target user was unbanned
    let channelType: String?
    /// The CID of the channel where the target user was unbanned
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let createdBy: UserPayload?
    let custom: [String: RawJSON]
    let receivedAt: Date?
    /// Whether the target user was shadow unbanned
    let shadow: Bool?
    /// The team of the channel where the target user was unbanned
    let team: String?
    /// The type of event: "user.unbanned" in this case
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
        createdBy: UserPayload? = nil,
        custom: [String: RawJSON],
        receivedAt: Date? = nil,
        shadow: Bool? = nil,
        team: String? = nil,
        type: String = "user.unbanned",
        user: UserPayload
    ) {
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.receivedAt = receivedAt
        self.shadow = shadow
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
        case createdBy = "created_by"
        case custom
        case receivedAt = "received_at"
        case shadow
        case team
        case type
        case user
    }
}

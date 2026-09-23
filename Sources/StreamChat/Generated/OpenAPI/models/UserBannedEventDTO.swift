//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserBannedEventDTO: Sendable, Event, Decodable {
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the target user was banned
    let channelId: String?
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel where the target user was banned
    let channelType: String?
    /// The CID of the channel where the target user was banned
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let createdBy: UserPayload?
    let custom: [String: RawJSON]
    /// The expiration date of the ban
    let expiration: Date?
    /// The reason for the ban
    let reason: String?
    let receivedAt: Date?
    /// ID of the review queue item (flagged message) that triggered the ban, if the ban was applied from the moderation review queue
    let reviewQueueItemId: String?
    /// Whether the user was shadow banned
    let shadow: Bool?
    /// The team of the channel where the target user was banned
    let team: String?
    let totalBans: Int?
    /// The type of event: "user.banned" in this case
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
        expiration: Date? = nil,
        reason: String? = nil,
        receivedAt: Date? = nil,
        reviewQueueItemId: String? = nil,
        shadow: Bool? = nil,
        team: String? = nil,
        totalBans: Int? = nil,
        type: String = "user.banned",
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
        self.expiration = expiration
        self.reason = reason
        self.receivedAt = receivedAt
        self.reviewQueueItemId = reviewQueueItemId
        self.shadow = shadow
        self.team = team
        self.totalBans = totalBans
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
        case expiration
        case reason
        case receivedAt = "received_at"
        case reviewQueueItemId = "review_queue_item_id"
        case shadow
        case team
        case totalBans = "total_bans"
        case type
        case user
    }
}

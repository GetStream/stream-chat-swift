//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserBannedEventDTO: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel where the target user was banned
    var channelId: String?
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel where the target user was banned
    var channelType: String?
    /// The CID of the channel where the target user was banned
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var createdBy: UserResponse?
    var custom: [String: RawJSON]
    /// The expiration date of the ban
    var expiration: Date?
    /// The reason for the ban
    var reason: String?
    var receivedAt: Date?
    /// ID of the review queue item (flagged message) that triggered the ban, if the ban was applied from the moderation review queue
    var reviewQueueItemId: String?
    /// Whether the user was shadow banned
    var shadow: Bool?
    /// The team of the channel where the target user was banned
    var team: String?
    var totalBans: Int?
    /// The type of event: "user.banned" in this case
    var type: String = "user.banned"
    var user: UserResponse

    init(channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, createdBy: UserResponse? = nil, custom: [String: RawJSON], expiration: Date? = nil, reason: String? = nil, receivedAt: Date? = nil, reviewQueueItemId: String? = nil, shadow: Bool? = nil, team: String? = nil, totalBans: Int? = nil, user: UserResponse) {
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

    static func == (lhs: UserBannedEventDTO, rhs: UserBannedEventDTO) -> Bool {
        lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.custom == rhs.custom &&
            lhs.expiration == rhs.expiration &&
            lhs.reason == rhs.reason &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.reviewQueueItemId == rhs.reviewQueueItemId &&
            lhs.shadow == rhs.shadow &&
            lhs.team == rhs.team &&
            lhs.totalBans == rhs.totalBans &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCustom)
        hasher.combine(channelId)
        hasher.combine(channelMemberCount)
        hasher.combine(channelMessageCount)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(custom)
        hasher.combine(expiration)
        hasher.combine(reason)
        hasher.combine(receivedAt)
        hasher.combine(reviewQueueItemId)
        hasher.combine(shadow)
        hasher.combine(team)
        hasher.combine(totalBans)
        hasher.combine(type)
        hasher.combine(user)
    }
}

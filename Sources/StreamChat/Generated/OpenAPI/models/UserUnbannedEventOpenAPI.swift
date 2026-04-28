//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserUnbannedEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel where the target user was unbanned
    var channelId: String?
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel where the target user was unbanned
    var channelType: String?
    /// The CID of the channel where the target user was unbanned
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var createdBy: UserResponseCommonFields?
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// Whether the target user was shadow unbanned
    var shadow: Bool?
    /// The team of the channel where the target user was unbanned
    var team: String?
    /// The type of event: "user.unbanned" in this case
    var type: String = "user.unbanned"
    var user: UserResponseCommonFields

    init(channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, createdBy: UserResponseCommonFields? = nil, custom: [String: RawJSON], receivedAt: Date? = nil, shadow: Bool? = nil, team: String? = nil, user: UserResponseCommonFields) {
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

    static func == (lhs: UserUnbannedEventOpenAPI, rhs: UserUnbannedEventOpenAPI) -> Bool {
        lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.shadow == rhs.shadow &&
            lhs.team == rhs.team &&
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
        hasher.combine(receivedAt)
        hasher.combine(shadow)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(user)
    }
}

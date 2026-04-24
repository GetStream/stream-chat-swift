//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserMessagesDeletedEventModel: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel where the target user's messages were deleted
    var channelId: String?
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel where the target user's messages were deleted
    var channelType: String?
    /// The CID of the channel where the target user's messages were deleted
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// Whether Messages were hard deleted
    var hardDelete: Bool?
    var receivedAt: Date?
    /// The team of the channel where the target user's messages were deleted
    var team: String?
    /// The type of event: "user.messages.deleted" in this case
    var type: String = "user.messages.deleted"
    var user: UserResponseCommonFields

    init(channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], hardDelete: Bool? = nil, receivedAt: Date? = nil, team: String? = nil, user: UserResponseCommonFields) {
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

    static func == (lhs: UserMessagesDeletedEventModel, rhs: UserMessagesDeletedEventModel) -> Bool {
        lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.hardDelete == rhs.hardDelete &&
            lhs.receivedAt == rhs.receivedAt &&
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
        hasher.combine(custom)
        hasher.combine(hardDelete)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(user)
    }
}

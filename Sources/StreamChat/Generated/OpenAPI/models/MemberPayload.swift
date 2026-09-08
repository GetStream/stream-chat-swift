//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberPayload: Sendable, Decodable {
    let archivedAt: Date?
    /// Expiration date of the ban
    let banExpires: Date?
    /// Whether the member's ban also applies to channels the channel's creator will create in the future (an active future channel ban by the creator targets this member)
    let banFromFutureChannels: Bool?
    /// Whether member is banned this channel or not
    let banned: Bool?
    /// Role of the member in the channel
    let channelRole: String?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let deletedAt: Date?
    let deletedMessages: [String]?
    /// Expiration date of the future channel ban; absent when the future channel ban is permanent
    let futureChannelBanExpires: Date?
    /// Date when invite was accepted
    let inviteAcceptedAt: Date?
    /// Date when invite was rejected
    let inviteRejectedAt: Date?
    /// Whether member was invited or not
    let invited: Bool?
    /// Whether member is channel moderator or not
    let isModerator: Bool?
    let notificationsMuted: Bool?
    let pinnedAt: Date?
    /// Permission level of the member in the channel (DEPRECATED: use channel_role instead). One of: member, moderator, admin, owner
    let role: String?
    /// Whether member is shadow banned in this channel or not
    let shadowBanned: Bool?
    let status: String?
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload?
    let userId: String?

    init(
        archivedAt: Date? = nil,
        banExpires: Date? = nil,
        banFromFutureChannels: Bool? = nil,
        banned: Bool? = nil,
        channelRole: String? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        deletedMessages: [String]? = nil,
        futureChannelBanExpires: Date? = nil,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil,
        invited: Bool? = nil,
        isModerator: Bool? = nil,
        notificationsMuted: Bool? = nil,
        pinnedAt: Date? = nil,
        role: String? = nil,
        shadowBanned: Bool? = nil,
        status: String? = nil,
        updatedAt: Date,
        user: UserPayload? = nil,
        userId: String? = nil
    ) {
        self.archivedAt = archivedAt
        self.banExpires = banExpires
        self.banFromFutureChannels = banFromFutureChannels
        self.banned = banned
        self.channelRole = channelRole
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.deletedMessages = deletedMessages
        self.futureChannelBanExpires = futureChannelBanExpires
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.invited = invited
        self.isModerator = isModerator
        self.notificationsMuted = notificationsMuted
        self.pinnedAt = pinnedAt
        self.role = role
        self.shadowBanned = shadowBanned
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case archivedAt = "archived_at"
        case banExpires = "ban_expires"
        case banFromFutureChannels = "ban_from_future_channels"
        case banned
        case channelRole = "channel_role"
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case deletedMessages = "deleted_messages"
        case futureChannelBanExpires = "future_channel_ban_expires"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
        case invited
        case isModerator = "is_moderator"
        case notificationsMuted = "notifications_muted"
        case pinnedAt = "pinned_at"
        case role
        case shadowBanned = "shadow_banned"
        case status
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        banExpires = try container.decodeIfPresent(Date.self, forKey: .banExpires)
        banFromFutureChannels = try container.decodeIfPresent(
            Bool.self,
            forKey: .banFromFutureChannels
        )
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned)
        channelRole = try container.decodeIfPresent(String.self, forKey: .channelRole)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        deletedMessages = try container.decodeIfPresent([String].self, forKey: .deletedMessages)
        futureChannelBanExpires = try container.decodeIfPresent(
            Date.self,
            forKey: .futureChannelBanExpires
        )
        inviteAcceptedAt = try container.decodeIfPresent(Date.self, forKey: .inviteAcceptedAt)
        inviteRejectedAt = try container.decodeIfPresent(Date.self, forKey: .inviteRejectedAt)
        invited = try container.decodeIfPresent(Bool.self, forKey: .invited)
        isModerator = try container.decodeIfPresent(Bool.self, forKey: .isModerator)
        notificationsMuted = try container.decodeIfPresent(Bool.self, forKey: .notificationsMuted)
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        shadowBanned = try container.decodeIfPresent(Bool.self, forKey: .shadowBanned)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}

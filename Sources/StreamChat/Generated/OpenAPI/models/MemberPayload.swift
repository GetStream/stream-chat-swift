//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberPayload: Sendable, Decodable {
    let archivedAt: Date?
    /// Expiration date of the ban
    let banExpires: Date?
    /// Whether member is banned this channel or not
    let banned: Bool
    /// Role of the member in the channel
    let channelRole: String
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let deletedAt: Date?
    /// Date when invite was accepted
    let inviteAcceptedAt: Date?
    /// Date when invite was rejected
    let inviteRejectedAt: Date?
    /// Whether member was invited or not
    let invited: Bool?
    let notificationsMuted: Bool
    let pinnedAt: Date?
    /// Whether member is shadow banned in this channel or not
    let shadowBanned: Bool
    let status: String?
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload?
    let userId: String?

    init(
        archivedAt: Date? = nil,
        banExpires: Date? = nil,
        banned: Bool,
        channelRole: String,
        createdAt: Date,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil,
        invited: Bool? = nil,
        notificationsMuted: Bool,
        pinnedAt: Date? = nil,
        shadowBanned: Bool,
        status: String? = nil,
        updatedAt: Date,
        user: UserPayload? = nil,
        userId: String? = nil
    ) {
        self.archivedAt = archivedAt
        self.banExpires = banExpires
        self.banned = banned
        self.channelRole = channelRole
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.invited = invited
        self.notificationsMuted = notificationsMuted
        self.pinnedAt = pinnedAt
        self.shadowBanned = shadowBanned
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        self.banExpires = try container.decodeIfPresent(Date.self, forKey: .banExpires)
        self.banned = try container.decodeIfPresent(Bool.self, forKey: .banned) ?? false
        self.channelRole = try container.decodeIfPresent(String.self, forKey: .channelRole) ?? "channel_member"
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        self.inviteAcceptedAt = try container.decodeIfPresent(Date.self, forKey: .inviteAcceptedAt)
        self.inviteRejectedAt = try container.decodeIfPresent(Date.self, forKey: .inviteRejectedAt)
        self.invited = try container.decodeIfPresent(Bool.self, forKey: .invited)
        self.notificationsMuted = try container.decodeIfPresent(
            Bool.self,
            forKey: .notificationsMuted
        ) ?? false
        self.pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        self.shadowBanned = try container.decodeIfPresent(Bool.self, forKey: .shadowBanned) ?? false
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}

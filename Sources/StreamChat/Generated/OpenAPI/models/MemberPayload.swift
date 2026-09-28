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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case archivedAt = "archived_at"
        case banExpires = "ban_expires"
        case banned
        case channelRole = "channel_role"
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
        case invited
        case notificationsMuted = "notifications_muted"
        case pinnedAt = "pinned_at"
        case shadowBanned = "shadow_banned"
        case status
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}

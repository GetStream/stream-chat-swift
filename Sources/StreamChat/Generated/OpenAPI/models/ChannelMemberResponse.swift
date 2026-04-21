//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelMemberResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var archivedAt: Date?
    /// Expiration date of the ban
    var banExpires: Date?
    /// Whether member is banned this channel or not
    var banned: Bool
    /// Role of the member in the channel
    var channelRole: String
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var deletedAt: Date?
    var deletedMessages: [String]?
    /// Date when invite was accepted
    var inviteAcceptedAt: Date?
    /// Date when invite was rejected
    var inviteRejectedAt: Date?
    /// Whether member was invited or not
    var invited: Bool?
    /// Whether member is channel moderator or not
    var isModerator: Bool?
    var notificationsMuted: Bool
    var pinnedAt: Date?
    /// Permission level of the member in the channel (DEPRECATED: use channel_role instead). One of: member, moderator, admin, owner
    var role: String?
    /// Whether member is shadow banned in this channel or not
    var shadowBanned: Bool
    var status: String?
    /// Date/time of the last update
    var updatedAt: Date
    var user: UserResponse?
    var userId: String?

    init(archivedAt: Date? = nil, banExpires: Date? = nil, banned: Bool, channelRole: String, createdAt: Date, custom: [String: RawJSON], deletedAt: Date? = nil, deletedMessages: [String]? = nil, inviteAcceptedAt: Date? = nil, inviteRejectedAt: Date? = nil, invited: Bool? = nil, isModerator: Bool? = nil, notificationsMuted: Bool, pinnedAt: Date? = nil, role: String? = nil, shadowBanned: Bool, status: String? = nil, updatedAt: Date, user: UserResponse? = nil, userId: String? = nil) {
        self.archivedAt = archivedAt
        self.banExpires = banExpires
        self.banned = banned
        self.channelRole = channelRole
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.deletedMessages = deletedMessages
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
        case banned
        case channelRole = "channel_role"
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case deletedMessages = "deleted_messages"
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

    static func == (lhs: ChannelMemberResponse, rhs: ChannelMemberResponse) -> Bool {
        lhs.archivedAt == rhs.archivedAt &&
            lhs.banExpires == rhs.banExpires &&
            lhs.banned == rhs.banned &&
            lhs.channelRole == rhs.channelRole &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.deletedMessages == rhs.deletedMessages &&
            lhs.inviteAcceptedAt == rhs.inviteAcceptedAt &&
            lhs.inviteRejectedAt == rhs.inviteRejectedAt &&
            lhs.invited == rhs.invited &&
            lhs.isModerator == rhs.isModerator &&
            lhs.notificationsMuted == rhs.notificationsMuted &&
            lhs.pinnedAt == rhs.pinnedAt &&
            lhs.role == rhs.role &&
            lhs.shadowBanned == rhs.shadowBanned &&
            lhs.status == rhs.status &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(archivedAt)
        hasher.combine(banExpires)
        hasher.combine(banned)
        hasher.combine(channelRole)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(deletedMessages)
        hasher.combine(inviteAcceptedAt)
        hasher.combine(inviteRejectedAt)
        hasher.combine(invited)
        hasher.combine(isModerator)
        hasher.combine(notificationsMuted)
        hasher.combine(pinnedAt)
        hasher.combine(role)
        hasher.combine(shadowBanned)
        hasher.combine(status)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}

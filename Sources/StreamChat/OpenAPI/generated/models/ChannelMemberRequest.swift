//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelMemberRequest: Codable, Hashable {
    public var banExpires: Date? = nil
    public var banned: Bool? = nil
    public var channelRole: String? = nil
    public var createdAt: Date? = nil
    public var deletedAt: Date? = nil
    public var inviteAcceptedAt: Date? = nil
    public var inviteRejectedAt: Date? = nil
    public var invited: Bool? = nil
    public var isModerator: Bool? = nil
    public var shadowBanned: Bool? = nil
    public var status: String? = nil
    public var updatedAt: Date? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(banExpires: Date? = nil, banned: Bool? = nil, channelRole: String? = nil, createdAt: Date? = nil, deletedAt: Date? = nil, inviteAcceptedAt: Date? = nil, inviteRejectedAt: Date? = nil, invited: Bool? = nil, isModerator: Bool? = nil, shadowBanned: Bool? = nil, status: String? = nil, updatedAt: Date? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.banExpires = banExpires
        self.banned = banned
        self.channelRole = channelRole
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.invited = invited
        self.isModerator = isModerator
        self.shadowBanned = shadowBanned
        self.status = status
        self.updatedAt = updatedAt
        self.userId = userId
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        case banned
        case channelRole = "channel_role"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
        case invited
        case isModerator = "is_moderator"
        case shadowBanned = "shadow_banned"
        case status
        case updatedAt = "updated_at"
        case userId = "user_id"
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(banExpires, forKey: .banExpires)
        try container.encode(banned, forKey: .banned)
        try container.encode(channelRole, forKey: .channelRole)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(deletedAt, forKey: .deletedAt)
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        try container.encode(invited, forKey: .invited)
        try container.encode(isModerator, forKey: .isModerator)
        try container.encode(shadowBanned, forKey: .shadowBanned)
        try container.encode(status, forKey: .status)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(userId, forKey: .userId)
        try container.encode(user, forKey: .user)
    }
}

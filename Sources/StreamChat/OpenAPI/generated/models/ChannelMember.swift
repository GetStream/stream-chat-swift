//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelMember: Codable, Hashable {
    public var banned: Bool
    public var channelRole: String
    public var createdAt: Date
    public var shadowBanned: Bool
    public var updatedAt: Date
    public var banExpires: Date? = nil
    public var deletedAt: Date? = nil
    public var inviteAcceptedAt: Date? = nil
    public var inviteRejectedAt: Date? = nil
    public var invited: Bool? = nil
    public var isModerator: Bool? = nil
    public var status: String? = nil
    public var userId: String? = nil
    public var user: UserObject? = nil

    public init(banned: Bool, channelRole: String, createdAt: Date, shadowBanned: Bool, updatedAt: Date, banExpires: Date? = nil, deletedAt: Date? = nil, inviteAcceptedAt: Date? = nil, inviteRejectedAt: Date? = nil, invited: Bool? = nil, isModerator: Bool? = nil, status: String? = nil, userId: String? = nil, user: UserObject? = nil) {
        self.banned = banned
        self.channelRole = channelRole
        self.createdAt = createdAt
        self.shadowBanned = shadowBanned
        self.updatedAt = updatedAt
        self.banExpires = banExpires
        self.deletedAt = deletedAt
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
        self.invited = invited
        self.isModerator = isModerator
        self.status = status
        self.userId = userId
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case channelRole = "channel_role"
        case createdAt = "created_at"
        case shadowBanned = "shadow_banned"
        case updatedAt = "updated_at"
        case banExpires = "ban_expires"
        case deletedAt = "deleted_at"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
        case invited
        case isModerator = "is_moderator"
        case status
        case userId = "user_id"
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(banned, forKey: .banned)
        try container.encode(channelRole, forKey: .channelRole)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(shadowBanned, forKey: .shadowBanned)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(banExpires, forKey: .banExpires)
        try container.encode(deletedAt, forKey: .deletedAt)
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        try container.encode(invited, forKey: .invited)
        try container.encode(isModerator, forKey: .isModerator)
        try container.encode(status, forKey: .status)
        try container.encode(userId, forKey: .userId)
        try container.encode(user, forKey: .user)
    }
}

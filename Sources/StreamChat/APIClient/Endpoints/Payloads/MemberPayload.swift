//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberContainerPayload: Decodable {
    let member: MemberPayload?
    let invite: MemberInvitePayload?
    let memberRole: MemberRolePayload?

    init(from decoder: Decoder) throws {
        member = try? .init(from: decoder)
        invite = try? .init(from: decoder)
        memberRole = try? .init(from: decoder)
    }

    init(
        member: MemberPayload?,
        invite: MemberInvitePayload?,
        memberRole: MemberRolePayload?
    ) {
        self.member = member
        self.invite = invite
        self.memberRole = memberRole
    }
}

struct MemberPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case userId = "user_id"
        case role = "channel_role"
        case isBanned = "banned"
        case isShadowBanned = "shadow_banned"
        case banExpiresAt = "ban_expires"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isInvited = "invited"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
    }

    let userId: String
    let user: UserPayload?
    let role: MemberRole?
    let createdAt: Date
    let updatedAt: Date

    /// If the member is banned from the channel, this field contains the date when the ban expires.
    let banExpiresAt: Date?

    /// Is true if the member is banned from the channel
    let isBanned: Bool?

    /// Is true if the member is shadow banned from the channel
    let isShadowBanned: Bool?

    /// Checks if he was invited.
    let isInvited: Bool?
    /// A date when an invited was accepted.
    let inviteAcceptedAt: Date?
    /// A date when an invited was rejected.
    let inviteRejectedAt: Date?

    init(
        user: UserPayload?,
        userId: String,
        role: MemberRole?,
        createdAt: Date,
        updatedAt: Date,
        banExpiresAt: Date? = nil,
        isBanned: Bool? = nil,
        isShadowBanned: Bool? = nil,
        isInvited: Bool? = nil,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil
    ) {
        self.user = user
        self.userId = userId
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.banExpiresAt = banExpiresAt
        self.isBanned = isBanned
        self.isShadowBanned = isShadowBanned
        self.isInvited = isInvited
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        role = try container.decodeIfPresent(MemberRole.self, forKey: .role)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        banExpiresAt = try container.decodeIfPresent(Date.self, forKey: .banExpiresAt)
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned)
        isShadowBanned = try container.decodeIfPresent(Bool.self, forKey: .isShadowBanned)
        isInvited = try container.decodeIfPresent(Bool.self, forKey: .isInvited)
        inviteAcceptedAt = try container.decodeIfPresent(Date.self, forKey: .inviteAcceptedAt)
        inviteRejectedAt = try container.decodeIfPresent(Date.self, forKey: .inviteRejectedAt)

        if let user = user {
            userId = user.id
        } else {
            userId = try container.decode(String.self, forKey: .userId)
        }
    }
}

struct MemberInvitePayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case role
        case isInvited = "invited"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
    }

    let role: MemberRole
    /// Checks if he was invited.
    let isInvited: Bool?
    /// A date when an invited was accepted.
    let inviteAcceptedAt: Date?
    /// A date when an invited was rejected.
    let inviteRejectedAt: Date?
}

struct MemberRolePayload: Decodable {
    let role: MemberRole
}

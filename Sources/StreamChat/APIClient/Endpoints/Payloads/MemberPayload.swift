//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberContainerPayload<ExtraData: UserExtraData>: Decodable {
    let member: MemberPayload<ExtraData>?
    let invite: MemberInvitePayload?
    let memberRole: MemberRolePayload?
    
    init(from decoder: Decoder) throws {
        member = try? .init(from: decoder)
        invite = try? .init(from: decoder)
        memberRole = try? .init(from: decoder)
    }
    
    init(
        member: MemberPayload<ExtraData>?,
        invite: MemberInvitePayload?,
        memberRole: MemberRolePayload?
    ) {
        self.member = member
        self.invite = invite
        self.memberRole = memberRole
    }
}

struct MemberPayload<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case role
        case isBanned = "banned"
        case isShadowBanned = "shadow_banned"
        case banExpiresAt = "ban_expires"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isInvited = "invited"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
    }
    
    let user: UserPayload<ExtraData>
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
        user: UserPayload<ExtraData>,
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

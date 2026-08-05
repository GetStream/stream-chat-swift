//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

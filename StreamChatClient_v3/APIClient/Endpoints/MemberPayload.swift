//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberContainerPayload<ExtraData: UserExtraData>: Decodable {
    let member: MemberPayload<ExtraData>?
    let invite: MemberInivePayload?
    let memberRole: MemberRolePayload?
    
    init(from decoder: Decoder) throws {
        member = try? .init(from: decoder)
        invite = try? .init(from: decoder)
        memberRole = try? .init(from: decoder)
    }
}

struct MemberPayload<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case role
        case created = "created_at"
        case updated = "updated_at"
        case isInvited = "invited"
        case inviteAcceptedAt = "invite_accepted_at"
        case inviteRejectedAt = "invite_rejected_at"
    }
    
    let user: UserPayload<ExtraData>
    let role: MemberRole?
    let created: Date
    let updated: Date
    /// Checks if he was invited.
    let isInvited: Bool?
    /// A date when an invited was accepted.
    let inviteAcceptedAt: Date?
    /// A date when an invited was rejected.
    let inviteRejectedAt: Date?
    
    init(user: UserPayload<ExtraData>,
         role: MemberRole?,
         created: Date,
         updated: Date,
         isInvited: Bool? = nil,
         inviteAcceptedAt: Date? = nil,
         inviteRejectedAt: Date? = nil) {
        self.user = user
        self.role = role
        self.created = created
        self.updated = updated
        self.isInvited = isInvited
        self.inviteAcceptedAt = inviteAcceptedAt
        self.inviteRejectedAt = inviteRejectedAt
    }
}

struct MemberInivePayload: Decodable {
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

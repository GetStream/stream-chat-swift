//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Request body for adding members to a user group
final class AddUserGroupMembersRequest: Sendable, Encodable, JSONEncodable {
    /// Whether to add the members as group admins. Defaults to false
    let asAdmin: Bool?
    /// List of user IDs to add as members
    let memberIds: [String]
    let teamId: String?

    init(asAdmin: Bool? = nil, memberIds: [String], teamId: String? = nil) {
        self.asAdmin = asAdmin
        self.memberIds = memberIds
        self.teamId = teamId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(asAdmin, forKey: .asAdmin)
        try container.encode(memberIds, forKey: .memberIds)
        try container.encodeIfPresent(teamId, forKey: .teamId)
    }
}

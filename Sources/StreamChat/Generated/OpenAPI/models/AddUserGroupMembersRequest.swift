//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case asAdmin = "as_admin"
        case memberIds = "member_ids"
        case teamId = "team_id"
    }
}

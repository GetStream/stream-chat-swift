//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AddUserGroupMembersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Whether to add the members as group admins. Defaults to false
    var asAdmin: Bool?
    /// List of user IDs to add as members
    var memberIds: [String]
    var teamId: String?

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

    static func == (lhs: AddUserGroupMembersRequest, rhs: AddUserGroupMembersRequest) -> Bool {
        lhs.asAdmin == rhs.asAdmin &&
            lhs.memberIds == rhs.memberIds &&
            lhs.teamId == rhs.teamId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(asAdmin)
        hasher.combine(memberIds)
        hasher.combine(teamId)
    }
}

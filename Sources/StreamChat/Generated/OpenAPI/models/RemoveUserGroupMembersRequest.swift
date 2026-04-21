//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RemoveUserGroupMembersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of user IDs to remove
    var memberIds: [String]
    var teamId: String?

    init(memberIds: [String], teamId: String? = nil) {
        self.memberIds = memberIds
        self.teamId = teamId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case memberIds = "member_ids"
        case teamId = "team_id"
    }

    static func == (lhs: RemoveUserGroupMembersRequest, rhs: RemoveUserGroupMembersRequest) -> Bool {
        lhs.memberIds == rhs.memberIds &&
            lhs.teamId == rhs.teamId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(memberIds)
        hasher.combine(teamId)
    }
}

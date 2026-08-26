//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RemoveUserGroupMembersRequest: Sendable, Codable, JSONEncodable {
    /// List of user IDs to remove
    let memberIds: [String]
    let teamId: String?

    init(memberIds: [String], teamId: String? = nil) {
        self.memberIds = memberIds
        self.teamId = teamId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case memberIds = "member_ids"
        case teamId = "team_id"
    }
}

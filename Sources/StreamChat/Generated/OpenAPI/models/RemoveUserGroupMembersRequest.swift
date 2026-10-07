//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Request body for removing members from a user group
final class RemoveUserGroupMembersRequest: Sendable, Encodable, JSONEncodable {
    /// List of user IDs to remove
    let memberIds: [String]
    let teamId: String?

    init(memberIds: [String], teamId: String? = nil) {
        self.memberIds = memberIds
        self.teamId = teamId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(memberIds, forKey: .memberIds)
        try container.encodeIfPresent(teamId, forKey: .teamId)
    }
}

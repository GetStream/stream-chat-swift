//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListUserGroupsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// List of user groups
    var userGroups: [UserGroupResponse]

    init(duration: String, userGroups: [UserGroupResponse]) {
        self.duration = duration
        self.userGroups = userGroups
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case userGroups = "user_groups"
    }

    static func == (lhs: ListUserGroupsResponse, rhs: ListUserGroupsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.userGroups == rhs.userGroups
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(userGroups)
    }
}

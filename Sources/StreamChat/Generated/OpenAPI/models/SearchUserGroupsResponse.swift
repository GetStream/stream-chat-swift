//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchUserGroupsResponse: Sendable, Codable, JSONEncodable {
    let duration: String
    /// List of matching user groups
    let userGroups: [UserGroupResponse]

    init(duration: String, userGroups: [UserGroupResponse]) {
        self.duration = duration
        self.userGroups = userGroups
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case userGroups = "user_groups"
    }
}

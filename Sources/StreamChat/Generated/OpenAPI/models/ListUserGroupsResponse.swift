//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListUserGroupsResponse: Sendable, Decodable {
    let duration: String
    /// List of user groups
    let userGroups: [UserGroup]

    init(
        duration: String,
        userGroups: [UserGroup]
    ) {
        self.duration = duration
        self.userGroups = userGroups
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case userGroups = "user_groups"
    }
}

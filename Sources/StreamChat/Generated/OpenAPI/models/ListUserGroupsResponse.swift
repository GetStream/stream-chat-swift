//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListUserGroupsResponse: Sendable, Decodable {
    /// List of user groups
    let userGroups: [UserGroup]

    init(userGroups: [UserGroup]) {
        self.userGroups = userGroups
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case userGroups = "user_groups"
    }
}

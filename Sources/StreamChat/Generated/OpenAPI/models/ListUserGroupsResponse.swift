//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// EmptyResponse for listing user groups
final class ListUserGroupsResponse: Sendable, Decodable {
    /// List of user groups
    let userGroups: [UserGroup]

    init(userGroups: [UserGroup]) {
        self.userGroups = userGroups
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.userGroups = try container.decode([UserGroup].self, forKey: .userGroups)
    }
}

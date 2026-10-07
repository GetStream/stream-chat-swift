//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// EmptyResponse for getting a user group
final class UserGroupResponse: Sendable, Decodable {
    let userGroup: UserGroup?

    init(userGroup: UserGroup? = nil) {
        self.userGroup = userGroup
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.userGroup = try container.decodeIfPresent(UserGroup.self, forKey: .userGroup)
    }
}

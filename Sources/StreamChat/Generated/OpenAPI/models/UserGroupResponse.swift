//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupResponse: Sendable, Decodable {
    let userGroup: UserGroup?

    init(userGroup: UserGroup? = nil) {
        self.userGroup = userGroup
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case userGroup = "user_group"
    }
}

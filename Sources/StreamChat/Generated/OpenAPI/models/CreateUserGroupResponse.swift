//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateUserGroupResponse: Sendable, Codable, JSONEncodable {
    let duration: String
    let userGroup: UserGroup?

    init(
        duration: String,
        userGroup: UserGroup? = nil
    ) {
        self.duration = duration
        self.userGroup = userGroup
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case userGroup = "user_group"
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUsersResponse: Sendable, Decodable {
    /// Object containing users
    let users: [String: FullUserResponse]

    init(users: [String: FullUserResponse]) {
        self.users = users
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.users = try container.decode([String: FullUserResponse].self, forKey: .users)
    }
}

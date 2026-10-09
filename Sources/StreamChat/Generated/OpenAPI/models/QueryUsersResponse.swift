//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryUsersResponse: Sendable, Decodable {
    /// Array of users as result of filters applied.
    let users: [FullUserResponse]

    init(users: [FullUserResponse]) {
        self.users = users
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.users = try container.decodeArrayIgnoringFailures(
            [FullUserResponse].self,
            forKey: .users
        )
    }
}

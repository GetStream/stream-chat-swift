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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }
}

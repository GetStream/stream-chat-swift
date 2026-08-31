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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }
}

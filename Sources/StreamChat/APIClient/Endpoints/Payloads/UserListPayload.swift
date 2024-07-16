//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserListPayload: Decodable, Sendable {
    /// A list of users response (see `UserListQuery`).
    let users: [UserPayload]
}

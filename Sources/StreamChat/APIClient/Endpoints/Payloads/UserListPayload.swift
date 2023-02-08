//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserListPayload: Decodable, Hashable {
    /// A list of users response (see `UserListQuery`).
    let users: [UserPayload]
}

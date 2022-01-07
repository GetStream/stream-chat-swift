//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserListPayload: Decodable {
    /// A list of users response (see `UserListQuery`).
    let users: [UserPayload]
}

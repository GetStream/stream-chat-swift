//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

package struct UserListPayload: Decodable {
    /// A list of users response (see `UserListQuery`).
    package let users: [UserPayload]
}

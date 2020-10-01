//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserListPayload<ExtraData: UserExtraData>: Decodable {
    /// A list of users response (see `UserListQuery`).
    let users: [UserPayload<ExtraData>]
}
